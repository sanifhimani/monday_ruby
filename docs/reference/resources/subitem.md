# Subitem

Access and manage subitems (child items) via the `client.subitem` resource.

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>What are Subitems?</span>
Subitems are child items that belong to a parent item. They help break down tasks into smaller, manageable pieces. Subitems live on their own separate board.
:::

## Methods

### query

Retrieves subitems for parent items.

```ruby
client.subitem.query(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Query arguments |
| `select` | Array | `["id", "name", "created_at"]` | Fields to retrieve |

**Returns:** `Monday::Response`

**Common args:**
- `ids` - Array of parent item IDs or single parent item ID

**Response Structure:**

The response contains items with their subitems nested:

```ruby
items = response.body.dig("data", "items")
subitems = items.first&.dig("subitems") || []
```

**Example:**

```ruby
# Query subitems for a parent item
response = client.subitem.query(
  args: { ids: [987654321] }
)

if response.success?
  items = response.body.dig("data", "items")
  subitems = items.first&.dig("subitems") || []

  puts "Found #{subitems.length} subitems"
  subitems.each do |subitem|
    puts "  • #{subitem['name']}"
  end
end
```

**Query multiple parent items:**

```ruby
response = client.subitem.query(
  args: { ids: [987654321, 987654322] },
  select: [
    "id",
    "name",
    "created_at",
    "state"
  ]
)

items = response.body.dig("data", "items")
items.each do |item|
  subitems = item["subitems"] || []
  puts "Item #{item['id']} has #{subitems.length} subitems"
end
```

**GraphQL:** `query { items { subitems { ... } } }`

**See:** [monday.com subitems query](https://developer.monday.com/api-reference/reference/subitems)

### create

Creates a new subitem under a parent item.

```ruby
client.subitem.create(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Creation arguments (required) |
| `select` | Array | `["id", "name", "created_at"]` | Fields to retrieve |

**Required args:**
- `parent_item_id` - Integer - The parent item ID
- `item_name` - String - Name of the subitem

**Optional args:**
- `column_values` - Hash or JSON String - Initial column values
- `create_labels_if_missing` - Boolean - Auto-create status labels

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.subitem.create(
  args: {
    parent_item_id: 987654321,
    item_name: "Design Phase"
  }
)

if response.success?
  subitem = response.body.dig("data", "create_subitem")
  puts "Created: #{subitem['name']}"
  puts "ID: #{subitem['id']}"
  puts "Created at: #{subitem['created_at']}"
end

# => Created: Design Phase
# => ID: 7092811738
# => Created at: 2024-07-25T04:00:04Z
```

**Create with column values:**

```ruby
# Note: Replace column IDs with your subitems board's actual column IDs
response = client.subitem.create(
  args: {
    parent_item_id: 987654321,
    item_name: "Development Task",
    column_values: {
      status: {  # Your status column ID
        label: "Working on it"
      },
      date4: {  # Your date column ID
        date: "2024-12-31"
      }
    }
  }
)
```

**GraphQL:** `mutation { create_subitem { ... } }`

**See:** [monday.com create_subitem](https://developer.monday.com/api-reference/reference/subitems#create-subitem)

## Updating and Deleting Subitems

Subitems are regular items, so use the standard item and column methods:

### Update Subitem Column Values

```ruby
# Use column.change_value or column.change_multiple_values
response = client.column.change_value(
  args: {
    board_id: 1234567890,  # Subitems board ID
    item_id: 7092811738,   # Subitem ID
    column_id: "status",   # Column ID
    value: JSON.generate({ label: "Done" })
  }
)
```

### Delete Subitem

```ruby
# Use item.delete
response = client.item.delete(7092811738)
```

### Archive Subitem

```ruby
# Use item.archive
response = client.item.archive(7092811738)
```

## Response Structure

All methods return a `Monday::Response` object. Access data using:

```ruby
response.success?  # => true/false
response.status    # => 200
response.body      # => Hash with GraphQL response
```

### Typical Response Pattern

```ruby
response = client.subitem.create(
  args: {
    parent_item_id: 987654321,
    item_name: "New Subitem"
  }
)

if response.success?
  subitem = response.body.dig("data", "create_subitem")
  # Work with subitem
else
  # Handle error
end
```

## Constants

### DEFAULT_SELECT

Default fields returned by `query` and `create`:

```ruby
["id", "name", "created_at"]
```

## Error Handling

Common errors when working with subitems:

- `Monday::AuthorizationError` - Invalid or missing API token
- `Monday::Error` - Invalid parent item ID, invalid field, or other API errors

**Example:**

```ruby
begin
  response = client.subitem.create(
    args: {
      parent_item_id: 123,  # Invalid ID
      item_name: "Test"
    }
  )
rescue Monday::Error => e
  puts "Error: #{e.message}"
end
```

See the [Error Handling guide](/guides/advanced/errors) for more details.

## Important Notes

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Subitems Board</span>
Subitems live on a separate board, not the parent board. To update subitem column values, you need the **subitems board ID**, not the parent board ID.
:::

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>No Nested Subitems</span>
Subitems cannot have their own subitems. monday.com only supports one level of parent-child relationship.
:::

## Related Resources

- [Item](/reference/resources/item) - Parent items
- [Column](/reference/resources/column) - Update subitem column values
- [Board](/reference/resources/board) - Query boards and items

## External References

- [monday.com Subitems API](https://developer.monday.com/api-reference/reference/subitems)
- [GraphQL API Overview](https://developer.monday.com/api-reference/docs/introduction-to-graphql)
