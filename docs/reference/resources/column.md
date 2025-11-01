# Column

Access and manage board columns via the `client.column` resource.

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>What are Columns?</span>
Columns define the structure of your board and the types of information you can track for each item (e.g., status, dates, people, text).
:::

## Methods

### query

Retrieves columns for boards.

```ruby
client.column.query(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Query arguments (see [boards query](https://developer.monday.com/api-reference/reference/boards#queries)) |
| `select` | Array | `["id", "title", "description"]` | Fields to retrieve |

**Returns:** `Monday::Response`

**Common args:**
- `ids` - Array of board IDs

**Response Structure:**

Columns are nested under boards:

```ruby
boards = response.body.dig("data", "boards")
columns = boards.first&.dig("columns") || []
```

**Example:**

```ruby
response = client.column.query(
  args: { ids: [1234567890] }
)

if response.success?
  boards = response.body.dig("data", "boards")
  columns = boards.first&.dig("columns") || []

  puts "Found #{columns.length} columns"
  columns.each do |column|
    puts "  • #{column['title']}: '#{column['id']}' (#{column['type']})"
  end
end
```

**GraphQL:** `query { boards { columns { ... } } }`

**See:** [monday.com columns query](https://developer.monday.com/api-reference/reference/columns)

### create

Creates a new column on a board.

```ruby
client.column.create(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Creation arguments (required) |
| `select` | Array | `["id", "title", "description"]` | Fields to retrieve |

**Required args:**
- `board_id` - Integer - Board ID
- `title` - String - Column title
- `column_type` - Symbol - Column type

**Optional args:**
- `description` - String - Column description
- `defaults` - String (JSON) - Default column settings

**Returns:** `Monday::Response`

**Available Column Types:**

- `:text` - Short text
- `:long_text` - Long text with formatting
- `:color` - Status with labels
- `:date` - Date and time
- `:people` - Person or team
- `:numbers` - Numeric values
- `:timeline` - Date range
- `:dropdown` - Dropdown selection
- `:email` - Email address
- `:phone` - Phone number
- `:link` - URL
- `:checkbox` - Checkbox
- `:rating` - Star rating
- `:hour` - Time tracking
- `:week` - Week selector
- `:country` - Country selector
- `:file` - File attachment
- `:location` - Geographic location
- `:tag` - Tags

**Example:**

```ruby
response = client.column.create(
  args: {
    board_id: 1234567890,
    title: "Priority",
    column_type: :color,
    description: "Task priority level"
  }
)

if response.success?
  column = response.body.dig("data", "create_column")
  puts "Created: #{column['title']} (ID: #{column['id']})"
end
```

**GraphQL:** `mutation { create_column { ... } }`

**See:** [monday.com create_column](https://developer.monday.com/api-reference/reference/columns#create-column)

### change_value

Updates a column value for a specific item.

```ruby
client.column.change_value(args: {}, select: ["id", "name"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Update arguments (required) |
| `select` | Array | `["id", "name"]` | Item fields to retrieve |

**Required args:**
- `board_id` - Integer - Board ID
- `item_id` - Integer - Item ID
- `column_id` - String - Column ID
- `value` - String (JSON) - New column value

**Optional args:**
- `create_labels_if_missing` - Boolean - Auto-create status labels

**Returns:** `Monday::Response`

**Example:**

```ruby
require "json"

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "status",
    value: JSON.generate({ label: "Done" })
  }
)

if response.success?
  item = response.body.dig("data", "change_column_value")
  puts "Updated: #{item['name']}"
end
```

**GraphQL:** `mutation { change_column_value { ... } }`

**See:** [monday.com change_column_value](https://developer.monday.com/api-reference/reference/columns#change-column-value)

### change_simple_value

Updates a simple column value (text, numbers).

```ruby
client.column.change_simple_value(args: {}, select: ["id", "name"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Update arguments (required) |
| `select` | Array | `["id", "name"]` | Item fields to retrieve |

**Required args:**
- `board_id` - Integer - Board ID
- `item_id` - Integer - Item ID
- `column_id` - String - Column ID
- `value` - String - New value

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.column.change_simple_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "text",
    value: "Updated text content"
  }
)

if response.success?
  item = response.body.dig("data", "change_simple_column_value")
  puts "Updated: #{item['name']}"
end
```

**GraphQL:** `mutation { change_simple_column_value { ... } }`

**See:** [monday.com change_simple_column_value](https://developer.monday.com/api-reference/reference/columns#change-simple-column-value)

### change_multiple_values

Updates multiple column values for an item at once.

```ruby
client.column.change_multiple_values(args: {}, select: ["id", "name"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Update arguments (required) |
| `select` | Array | `["id", "name"]` | Item fields to retrieve |

**Required args:**
- `board_id` - Integer - Board ID
- `item_id` - Integer - Item ID
- `column_values` - String (JSON) - Hash of column values

**Optional args:**
- `create_labels_if_missing` - Boolean - Auto-create status labels

**Returns:** `Monday::Response`

**Example:**

```ruby
require "json"

column_values = {
  status: { label: "Working on it" },
  text: "High priority",
  numbers: 85
}

response = client.column.change_multiple_values(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_values: JSON.generate(column_values)
  }
)

if response.success?
  item = response.body.dig("data", "change_multiple_column_values")
  puts "Updated multiple columns for: #{item['name']}"
end
```

**GraphQL:** `mutation { change_multiple_column_values { ... } }`

**See:** [monday.com change_multiple_column_values](https://developer.monday.com/api-reference/reference/columns#change-multiple-column-values)

### change_title

Updates a column's title.

```ruby
client.column.change_title(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Update arguments (required) |
| `select` | Array | `["id", "title", "description"]` | Fields to retrieve |

**Required args:**
- `board_id` - Integer - Board ID
- `column_id` - String - Column ID
- `title` - String - New title

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.column.change_title(
  args: {
    board_id: 1234567890,
    column_id: "text_1",
    title: "Project Notes"
  }
)

if response.success?
  column = response.body.dig("data", "change_column_title")
  puts "Renamed to: #{column['title']}"
end
```

**GraphQL:** `mutation { change_column_title { ... } }`

**See:** [monday.com change_column_title](https://developer.monday.com/api-reference/reference/columns#change-column-title)

### change_metadata

Updates column metadata (settings, description).

```ruby
client.column.change_metadata(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Update arguments (required) |
| `select` | Array | `["id", "title", "description"]` | Fields to retrieve |

**Required args:**
- `board_id` - Integer - Board ID
- `column_id` - String - Column ID
- `column_property` - String - Property to update (e.g., "description", "labels")
- `value` - String - New value (JSON for complex properties)

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.column.change_metadata(
  args: {
    board_id: 1234567890,
    column_id: "status",
    column_property: "description",
    value: "Current task status"
  }
)

if response.success?
  column = response.body.dig("data", "change_column_metadata")
  puts "Metadata updated for: #{column['title']}"
end
```

**GraphQL:** `mutation { change_column_metadata { ... } }`

**See:** [monday.com change_column_metadata](https://developer.monday.com/api-reference/reference/columns#change-column-metadata)

### delete

Deletes a column from a board.

```ruby
client.column.delete(board_id, column_id, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `board_id` | Integer | - | Board ID (required) |
| `column_id` | String | - | Column ID to delete (required) |
| `select` | Array | `["id"]` | Fields to retrieve |

**Returns:** `Monday::Response`

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Permanent Deletion</span>
Deleting a column removes it and all its data from every item. This cannot be undone.
:::

**Example:**

```ruby
response = client.column.delete(1234567890, "text_1")

if response.success?
  column = response.body.dig("data", "delete_column")
  puts "Deleted column ID: #{column['id']}"
end
```

**GraphQL:** `mutation { delete_column { ... } }`

**See:** [monday.com delete_column](https://developer.monday.com/api-reference/reference/columns#delete-column)

### column_values (Deprecated)

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Deprecated</span>
This method is deprecated and will be removed in v2.0.0. Use `client.item.query` with `column_values` select instead.
:::

## Response Structure

All methods return a `Monday::Response` object. Access data using:

```ruby
response.success?  # => true/false
response.status    # => 200
response.body      # => Hash with GraphQL response
```

### Typical Response Pattern

```ruby
response = client.column.create(
  args: {
    board_id: 1234567890,
    title: "Status",
    column_type: :color
  }
)

if response.success?
  column = response.body.dig("data", "create_column")
  # Work with column
else
  # Handle error
end
```

## Constants

### DEFAULT_SELECT

Default fields returned by most column methods:

```ruby
["id", "title", "description"]
```

## Error Handling

Common errors when working with columns:

- `Monday::AuthorizationError` - Invalid or missing API token
- `Monday::InvalidRequestError` - Invalid board ID or column ID
- `Monday::Error` - Invalid column type, invalid field, or other API errors

**Example:**

```ruby
begin
  response = client.column.create(
    args: {
      board_id: 123,  # Invalid ID
      title: "Test",
      column_type: :text
    }
  )
rescue Monday::InvalidRequestError => e
  puts "Error: #{e.message}"
end
```

See the [Error Handling guide](/guides/advanced/errors) for more details.

## Column Value Formats

Different column types require different value formats:

### Status (Color)

```ruby
{ label: "Done" }
# or
{ index: 1 }
```

### Date

```ruby
{ date: "2024-12-31" }
# or
{ date: "2024-12-31", time: "14:30:00" }
```

### People

```ruby
{
  personsAndTeams: [
    { id: 12345678, kind: "person" }
  ]
}
```

### Timeline

```ruby
{ from: "2024-01-01", to: "2024-03-31" }
```

### Link

```ruby
{ url: "https://example.com", text: "Example" }
```

### Email

```ruby
{ email: "user@example.com", text: "Contact" }
```

### Checkbox

```ruby
{ checked: "true" }
```

See the [Update Column Values guide](/guides/columns/update-values) for complete examples of all column types.

## Related Resources

- [Item](/reference/resources/item) - Items with column values
- [Board](/reference/resources/board) - Boards containing columns
- [Group](/reference/resources/group) - Groups organizing items

## External References

- [monday.com Columns API](https://developer.monday.com/api-reference/reference/columns)
- [GraphQL API Overview](https://developer.monday.com/api-reference/docs/introduction-to-graphql)
- [Column Types](https://support.monday.com/hc/en-us/articles/115005483545-All-About-Columns)
