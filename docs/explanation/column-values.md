# Column Values in monday.com

This document explains the concept of column values, their types, formats, and why they work the way they do in the monday.com API.

## What are Column Values?

In monday.com, column values are the data stored in the cells of a board. Each item (row) has values for each column (field) defined on its board. Unlike traditional databases where column types are strictly defined, monday.com supports a rich variety of column types, each with its own value structure and behavior.

### The monday.com Data Model

```
Board
├── Group 1
│   ├── Item A
│   │   ├── Status Column: "Done"
│   │   ├── Date Column: "2024-01-15"
│   │   └── Person Column: [User 123, User 456]
│   └── Item B
└── Group 2
```

Each cell in this structure contains a column value. The structure and meaning of that value depends on the column type.

### Column Values vs Column Definitions

It's important to distinguish between:

- **Column definition**: The column itself (its ID, type, title, settings)
- **Column value**: The data stored in that column for a specific item

For example:
- Column definition: `{id: "status", type: "status", title: "Project Status"}`
- Column value: `{label: "In Progress", index: 1}`

## Column Types and Their Value Formats

monday.com supports numerous column types, each requiring a specific value format.

### Simple Column Types

Some column types store simple, straightforward values:

**Text**
```json
"This is a text value"
```

**Number**
```json
"42"
```

**Checkbox**
```json
{"checked": true}
```

### Complex Column Types

Many column types have structured, complex values:

**Status**
```json
{
  "label": "Done",
  "index": 2
}
```
Contains both the display label and the index (position in status options).

**Date**
```json
{
  "date": "2024-01-15",
  "time": "14:30:00"
}
```
Supports date-only or date+time values.

**Person**
```json
{
  "personsAndTeams": [
    {"id": 12345, "kind": "person"},
    {"id": 67890, "kind": "team"}
  ]
}
```
Can reference multiple people and/or teams.

**Dropdown**
```json
{
  "labels": ["Option 1", "Option 2"]
}
```
Single or multiple selections depending on column settings.

**Link**
```json
{
  "url": "https://example.com",
  "text": "Example Website"
}
```
URL with optional display text.

**Phone**
```json
{
  "phone": "+1-555-123-4567",
  "countryShortName": "US"
}
```
Phone number with country code.

**Email**
```json
{
  "email": "user@example.com",
  "text": "John Doe"
}
```
Email address with optional display name.

**Location**
```json
{
  "lat": "37.7749",
  "lng": "-122.4194",
  "address": "San Francisco, CA"
}
```
Geographic coordinates and address.

**Timeline**
```json
{
  "from": "2024-01-01",
  "to": "2024-12-31"
}
```
Date range with start and end dates.

## Why Different Column Types Need Different JSON Structures

The structural diversity in column value formats reflects the semantic differences between data types.

### Semantic Richness

Each column type represents different real-world concepts:

- **Status**: Requires both a label (what users see) and an index (for ordering/grouping)
- **Person**: Must distinguish between individual users and teams, and support multiple assignments
- **Date**: Needs to handle date-only and date-time scenarios differently
- **Link**: Separates the destination URL from the display text

### Backend Processing

Different column types trigger different backend behaviors:

- **Person columns**: Trigger notifications to assigned users
- **Status columns**: Update board analytics and dashboards
- **Date columns**: Power timeline views and deadline reminders
- **Formula columns**: Recalculate when dependent values change

The value format provides the data needed for these behaviors.

### Validation Requirements

Each column type has unique validation needs:

- **Email**: Must validate email format
- **Phone**: Must validate phone number format and country code
- **Date**: Must validate date is valid and in correct format
- **Dropdown**: Must validate selection exists in column settings

The structured format enables server-side validation.

### UI Rendering

The monday.com interface renders each column type differently:

- **Status**: Colored labels with icons
- **Person**: Avatar images with names
- **Date**: Calendar picker
- **Timeline**: Gantt chart visualization

The value structure includes all information needed for rendering.

## Simple vs Complex Column Values

Column values exist on a spectrum from simple to complex.

### Simple Column Values

Types like text, number, and checkbox are "simple":
- Single primitive value or shallow object
- Minimal structure
- Easy to read and write
- Limited backend processing

```json
"Simple text"
```

### Complex Column Values

Types like person, board relation, and mirror are "complex":
- Deeply nested structures
- Multiple data points
- References to other entities
- Extensive backend processing

```json
{
  "item_ids": [123, 456, 789],
  "linkedPulseIds": [
    {"linkedPulseId": 123},
    {"linkedPulseId": 456}
  ]
}
```

### The Complexity Spectrum

```
Simple                                           Complex
├─────────┼─────────┼─────────┼─────────┼─────────┤
Text    Number   Status    Person    Board-Relation
        Checkbox  Date      Dropdown  Mirror
                  Link      Timeline  Formula
```

Complexity affects:
- **API payload size**: Complex values require more data
- **Validation logic**: Complex values have more validation rules
- **Query performance**: Complex values may require joins or lookups
- **Update latency**: Complex values may trigger cascading updates

## Column IDs vs Column Titles

Understanding the difference between column IDs and titles is crucial for working with column values.

### Column Title

The title is the human-readable name displayed in the monday.com interface:
- "Project Status"
- "Due Date"
- "Assigned To"

Titles are:
- User-facing and editable
- Not guaranteed to be unique
- Can change at any time
- Localized in some cases

### Column ID

The ID is a unique identifier for the column:
- "status"
- "date4"
- "person"

IDs are:
- System-facing and stable
- Guaranteed unique within a board
- Generally don't change (though they can)
- Not localized

### Why IDs are Board-Specific

Column IDs are only unique within a board:
- Board A can have a column with ID "status"
- Board B can also have a column with ID "status"
- These are different columns with potentially different settings

This means:
- You cannot assume column ID "status" has the same meaning across boards
- When working with multiple boards, track board ID + column ID
- Column settings (like status options) are board-specific

### API Usage

The API uses column IDs, not titles:

```ruby
# Correct: Use column ID
client.item.change_column_value(
  args: {
    board_id: 123,
    item_id: 456,
    column_id: "status",  # Column ID
    value: '{"label": "Done"}'
  }
)

# Incorrect: Cannot use column title
client.item.change_column_value(
  args: {
    column_id: "Project Status",  # Won't work!
    ...
  }
)
```

### Finding Column IDs

To find column IDs:
1. Query the board's columns
2. Match by title to find the corresponding ID
3. Use the ID in subsequent operations

```ruby
# Get column information
response = client.board.query(
  args: { ids: [123] },
  select: [{ columns: ["id", "title", "type"] }]
)

# Find column ID by title
columns = response.dig("data", "boards", 0, "columns")
status_column = columns.find { |col| col["title"] == "Project Status" }
column_id = status_column["id"]  # Use this ID
```

## JSON Serialization Requirements

Column values are passed as JSON strings in the monday.com API, which has important implications.

### Why JSON Strings?

The API requires column values as JSON-encoded strings rather than native objects:

```ruby
# Correct: JSON string
value = '{"label": "Done"}'

# Incorrect: Ruby hash
value = {label: "Done"}  # Won't work!
```

**Reasons for this design**:

1. **GraphQL limitations**: GraphQL mutations require static types, but column values vary by column type
2. **Flexibility**: JSON strings can represent any column type without defining dozens of input types
3. **Backward compatibility**: New column types can be added without API changes
4. **Validation**: Server can validate after parsing based on actual column type

### Serialization Process

When setting a column value:

1. **Construct**: Build a Ruby hash with the value structure
   ```ruby
   value_hash = {label: "Done", index: 2}
   ```

2. **Serialize**: Convert to JSON string
   ```ruby
   value_json = value_hash.to_json
   # => '{"label":"Done","index":2}'
   ```

3. **Send**: Pass the JSON string to the API
   ```ruby
   client.item.change_column_value(
     args: { column_id: "status", value: value_json }
   )
   ```

### Deserialization Process

When reading column values:

1. **Receive**: Get JSON string from API
   ```ruby
   column_value = response.dig("data", "items", 0, "column_values", 0, "value")
   # => '{"label":"Done","index":2}'
   ```

2. **Parse**: Convert from JSON string to Ruby hash
   ```ruby
   value_hash = JSON.parse(column_value)
   # => {"label"=>"Done", "index"=>2}
   ```

3. **Use**: Access the parsed data
   ```ruby
   label = value_hash["label"]  # => "Done"
   ```

### Common Serialization Pitfalls

**Double encoding**:
```ruby
# Wrong: Double encoding
value = {label: "Done"}.to_json.to_json
# => '"{\"label\":\"Done\"}"'  # Escaped quotes!

# Correct: Single encoding
value = {label: "Done"}.to_json
# => '{"label":"Done"}'
```

**Symbol vs string keys**:
```ruby
# Both work, but consistency matters
{label: "Done"}.to_json        # => '{"label":"Done"}'
{"label" => "Done"}.to_json    # => '{"label":"Done"}'

# Parsing returns string keys
JSON.parse('{"label":"Done"}')
# => {"label"=>"Done"}  # String keys, not symbols
```

**Escaping**:
```ruby
# Special characters must be properly escaped
value = {text: 'Quote: "Hello"'}.to_json
# => '{"text":"Quote: \"Hello\""}'
```

## change_value vs change_simple_value vs change_multiple_values

monday.com provides multiple methods for updating column values, each optimized for different scenarios.

### change_column_value

Updates a single column value on a single item:

```ruby
client.item.change_column_value(
  args: {
    board_id: 123,
    item_id: 456,
    column_id: "status",
    value: '{"label": "Done"}'
  }
)
```

**Characteristics**:
- Most explicit and clear
- Requires full value structure
- Works with any column type
- Validates against column type
- Returns updated item

**Use when**:
- Updating complex column values
- Need full control over value structure
- Working with a single column

### change_simple_column_value

Simplified version for common column types:

```ruby
client.item.change_simple_column_value(
  args: {
    board_id: 123,
    item_id: 456,
    column_id: "text_column",
    value: "Simple text"  # Plain string, not JSON
  }
)
```

**Characteristics**:
- Accepts plain strings for simple types
- Automatically handles JSON encoding
- Limited to simple column types (text, number)
- Less flexible than `change_column_value`

**Use when**:
- Updating text or number columns
- Value is a simple string or number
- Want simplified API

### change_multiple_column_values

Updates multiple columns on a single item in one request:

```ruby
client.item.change_multiple_column_values(
  args: {
    board_id: 123,
    item_id: 456,
    column_values: {
      status: {label: "Done"},
      date4: {date: "2024-01-15"},
      person: {personsAndTeams: [{id: 12345, kind: "person"}]}
    }.to_json
  }
)
```

**Characteristics**:
- Updates multiple columns atomically
- More efficient than multiple single-column updates
- Reduces API calls and complexity
- Single validation and response

**Use when**:
- Updating several columns at once
- Creating items with initial values
- Want to minimize API requests
- Need atomic updates (all or nothing)

### Method Comparison

| Method | Columns per Call | Value Format | Complexity | Use Case |
|--------|-----------------|--------------|------------|----------|
| `change_column_value` | 1 | JSON string | Medium | Single column, any type |
| `change_simple_column_value` | 1 | Plain string | Low | Simple types only |
| `change_multiple_column_values` | Multiple | JSON string | Higher | Batch updates |

### Performance Implications

**Multiple single updates**:
```ruby
# 3 API calls
client.item.change_column_value(args: {column_id: "status", ...})
client.item.change_column_value(args: {column_id: "date4", ...})
client.item.change_column_value(args: {column_id: "person", ...})
```

**Single batch update**:
```ruby
# 1 API call
client.item.change_multiple_column_values(
  args: {
    column_values: {
      status: {...},
      date4: {...},
      person: {...}
    }.to_json
  }
)
```

Batch updates:
- 3× fewer API calls
- 3× less authentication overhead
- Lower total complexity
- Faster total execution
- Atomic (all succeed or all fail)

## Column Value Validation

Validation of column values happens on the monday.com server, not in the API client.

### Server-Side Validation

When you submit a column value, monday.com validates:

1. **Type compatibility**: Value structure matches column type
2. **Required fields**: All necessary fields are present
3. **Value constraints**: Values are within allowed ranges/options
4. **Reference validity**: Referenced entities (users, boards, etc.) exist
5. **Permissions**: User has permission to set the value

### Why Server-Side?

- **Authoritative**: Board configuration is server-controlled
- **Dynamic**: Column settings can change
- **Security**: Client-side validation can be bypassed
- **Consistency**: Same validation for all API clients
- **Complex rules**: Some validation requires server data

### Validation Errors

Invalid column values return errors:

```ruby
# Invalid status label
client.item.change_column_value(
  args: {
    column_id: "status",
    value: '{"label": "Invalid Status"}'
  }
)
# Error: "Status label 'Invalid Status' does not exist"
```

```ruby
# Invalid date format
client.item.change_column_value(
  args: {
    column_id: "date4",
    value: '{"date": "2024-13-45"}'  # Invalid date
  }
)
# Error: "Invalid date format"
```

### Validation Strategy

Best practices for handling validation:

1. **Query column settings**: Fetch column configuration to know valid options
2. **Validate client-side**: Pre-validate when possible to avoid API calls
3. **Handle errors**: Catch and handle validation errors gracefully
4. **Test edge cases**: Test with boundary values and edge cases
5. **Monitor changes**: Watch for board configuration changes that affect validation

### Example: Status Column Validation

```ruby
# 1. Get valid status options
board = client.board.query(
  args: { ids: [123] },
  select: [{ columns: ["id", "settings_str"] }]
)

status_column = board.dig("data", "boards", 0, "columns")
  .find { |c| c["id"] == "status" }

settings = JSON.parse(status_column["settings_str"])
valid_labels = settings["labels"].keys
# => ["Not Started", "In Progress", "Done"]

# 2. Validate before sending
label = "Done"
if valid_labels.include?(label)
  client.item.change_column_value(
    args: {
      column_id: "status",
      value: {label: label}.to_json
    }
  )
else
  # Handle invalid label
  puts "Invalid status: #{label}"
end
```

## Common Column Value Patterns

Certain patterns appear frequently when working with column values.

### Clearing a Column Value

To clear a column value, set it to an empty object or null:

```ruby
# Clear status column
client.item.change_column_value(
  args: {
    column_id: "status",
    value: '{}'
  }
)

# Clear text column
client.item.change_simple_column_value(
  args: {
    column_id: "text_column",
    value: ""
  }
)
```

### Copying Column Values Between Items

```ruby
# Get source item's column value
source = client.item.query(
  args: { ids: [123] },
  select: [{ column_values: ["id", "value"] }]
)

status_value = source.dig("data", "items", 0, "column_values")
  .find { |cv| cv["id"] == "status" }["value"]

# Set on destination item
client.item.change_column_value(
  args: {
    item_id: 456,
    column_id: "status",
    value: status_value  # Already JSON string
  }
)
```

### Conditional Updates

```ruby
# Update only if current value meets condition
item = client.item.query(
  args: { ids: [123] },
  select: [{ column_values: ["id", "value"] }]
)

status = JSON.parse(
  item.dig("data", "items", 0, "column_values")
    .find { |cv| cv["id"] == "status" }["value"]
)

if status["label"] == "In Progress"
  # Move to Done
  client.item.change_column_value(
    args: {
      column_id: "status",
      value: '{"label": "Done"}'
    }
  )
end
```

### Bulk Updates Across Items

```ruby
# Update same column on multiple items
item_ids = [123, 456, 789]
value = '{"label": "Done"}'

item_ids.each do |item_id|
  client.item.change_column_value(
    args: {
      item_id: item_id,
      column_id: "status",
      value: value
    }
  )
end
```

### Setting Values on Item Creation

```ruby
# Create item with initial column values
client.item.create(
  args: {
    board_id: 123,
    item_name: "New Task",
    column_values: {
      status: {label: "Not Started"},
      date4: {date: "2024-12-31"},
      person: {
        personsAndTeams: [
          {id: 12345, kind: "person"}
        ]
      }
    }.to_json
  }
)
```

## Why Column Values are Strings/JSON

The decision to represent column values as JSON strings rather than native types has deep architectural reasons.

### GraphQL Type System Constraints

GraphQL requires mutations to have statically-typed inputs:

```graphql
# GraphQL requires knowing exact type at schema definition time
mutation {
  change_column_value(
    column_id: "status",
    value: StatusInput  # Must be a defined input type
  )
}
```

With 30+ column types, each with different structures:
- Defining 30+ input types would be complex
- Adding new column types would break API compatibility
- Clients would need to know all types

### JSON as Universal Type

Using JSON strings provides a universal interface:

```graphql
mutation {
  change_column_value(
    column_id: String!,
    value: JSON!  # Universal type
  )
}
```

Benefits:
- Single input type for all column values
- New column types don't require schema changes
- Backward compatible
- Forward compatible

### Runtime Type Resolution

With JSON strings, monday.com can:

1. **Receive** the value as a string
2. **Parse** the JSON
3. **Look up** the column type from the database
4. **Validate** based on actual column type
5. **Process** type-specific logic

This allows dynamic, runtime type handling instead of static, compile-time types.

### Trade-off: Type Safety vs Flexibility

**Type safety (if native objects were used)**:
- Compile-time validation
- Better IDE autocomplete
- Catch errors earlier
- More complex API

**Flexibility (current JSON string approach)**:
- Runtime validation
- Limited IDE support
- Errors caught later
- Simpler API

monday.com chose flexibility to support its rapidly evolving column type system.

### Client Library Implications

The monday_ruby gem could provide typed wrappers:

```ruby
# Hypothetical typed wrapper (not currently implemented)
StatusValue.new(label: "Done", index: 2).to_json
# => '{"label":"Done","index":2}'
```

This would provide:
- Type safety in Ruby
- Validation before API call
- Better developer experience
- Documentation through code

But would require:
- Maintaining type definitions for all column types
- Updates when monday.com adds column types
- Additional abstraction layer

Currently, monday_ruby passes JSON strings directly, keeping the API thin and flexible.

## Conclusion

Column values are the core data model in monday.com, representing diverse types of information with varying structural complexity. Understanding column values requires grasping several key concepts:

- **Type diversity**: Different column types have different value structures reflecting their semantic meaning
- **JSON serialization**: Values are passed as JSON strings due to GraphQL constraints and flexibility requirements
- **Column identification**: Column IDs, not titles, are used for API operations and are board-specific
- **Multiple update methods**: Different methods (`change_column_value`, `change_simple_column_value`, `change_multiple_column_values`) optimize for different scenarios
- **Server-side validation**: monday.com validates column values based on board configuration and column settings
- **Common patterns**: Clearing values, copying between items, and bulk updates follow established patterns

The JSON string approach, while requiring extra serialization steps, provides the flexibility necessary for monday.com's rich and evolving column type system. The monday_ruby gem preserves this design while providing Ruby-friendly interfaces for building and parsing these values.

Understanding these concepts enables you to effectively work with monday.com's data model, choose the right update methods, handle validation properly, and build robust integrations.
