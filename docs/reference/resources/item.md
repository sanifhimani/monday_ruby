# Item

Access and manage items via the `client.item` resource.

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Finding Column IDs</span>
Many item operations require column IDs. These are board-specific. Query your board's columns first:

```ruby
response = client.board.query(
  args: { ids: [1234567890] },
  select: ["id", { columns: ["id", "title", "type"] }]
)
```

See the [Create Items guide](/guides/items/create#finding-column-ids) for a complete example.
:::

## Methods

### query

Retrieves items from your account.

```ruby
client.item.query(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Query arguments (see [items query](https://developer.monday.com/api-reference/reference/items#queries)) |
| `select` | Array | `["id", "name", "created_at"]` | Fields to retrieve |

**Returns:** `Monday::Response`

**Common args:**
- `ids` - Array of item IDs or single item ID as string
- `limit` - Number of results (default: 25)
- `page` - Page number
- `newest_first` - Boolean, sort by creation date

**Example:**

```ruby
response = client.item.query(
  args: { ids: [123456, 789012] },
  select: ["id", "name", "created_at", "state"]
)

items = response.body.dig("data", "items")
```

**GraphQL:** `query { items { ... } }`

**See:** [monday.com items query](https://developer.monday.com/api-reference/reference/items#queries)

### create

Creates a new item.

```ruby
client.item.create(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Creation arguments (required) |
| `select` | Array | `["id", "name", "created_at"]` | Fields to retrieve |

**Required args:**
- `board_id` - Integer or String
- `item_name` - String

**Optional args:**
- `group_id` - String - Group to create item in
- `column_values` - Hash or JSON String - Initial column values
- `create_labels_if_missing` - Boolean - Auto-create status labels

**Returns:** `Monday::Response`

**Example:**

```ruby
# Note: Replace column IDs with your board's actual column IDs
response = client.item.create(
  args: {
    board_id: 123456,
    item_name: "New Task",
    column_values: {
      status: {  # Use your board's status column ID
        label: "Done"
      }
    }
  }
)

item = response.body.dig("data", "create_item")
# => {"id"=>"18273372913", "name"=>"New Task", "created_at"=>"2025-10-27T02:17:50Z"}
```

**GraphQL:** `mutation { create_item { ... } }`

**See:** [monday.com create_item](https://developer.monday.com/api-reference/reference/items#create-item)

### duplicate

Duplicates an existing item.

```ruby
client.item.duplicate(board_id, item_id, with_updates, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `board_id` | Integer | - | Board ID (required) |
| `item_id` | Integer | - | Item ID to duplicate (required) |
| `with_updates` | Boolean | - | Include update threads (required) |
| `select` | Array | `["id", "name", "created_at"]` | Fields to retrieve |

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.item.duplicate(123456, 789012, true)

duplicated_item = response.body.dig("data", "duplicate_item")
```

**GraphQL:** `mutation { duplicate_item { ... } }`

**See:** [monday.com duplicate_item](https://developer.monday.com/api-reference/reference/items#duplicate-item)

### archive

Archives an item.

```ruby
client.item.archive(item_id, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `item_id` | Integer | - | Item ID to archive (required) |
| `select` | Array | `["id"]` | Fields to retrieve |

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.item.archive(123456)

archived_item = response.body.dig("data", "archive_item")
```

**GraphQL:** `mutation { archive_item { ... } }`

**See:** [monday.com archive_item](https://developer.monday.com/api-reference/reference/items#archive-item)

### delete

Permanently deletes an item.

```ruby
client.item.delete(item_id, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `item_id` | Integer | - | Item ID to delete (required) |
| `select` | Array | `["id"]` | Fields to retrieve |

**Returns:** `Monday::Response`

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Permanent Deletion</span>
This operation cannot be undone. All item data will be permanently lost.
:::

**Example:**

```ruby
response = client.item.delete(123456)

deleted_item = response.body.dig("data", "delete_item")
# => {"id"=>"123456"}
```

**GraphQL:** `mutation { delete_item { ... } }`

**See:** [monday.com delete_item](https://developer.monday.com/api-reference/reference/items#delete-item)

### page_by_column_values

Retrieves paginated items filtered by column values using cursor-based pagination.

```ruby
client.item.page_by_column_values(
  board_id:,
  columns: nil,
  limit: 25,
  cursor: nil,
  select: DEFAULT_PAGINATED_SELECT
)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `board_id` | Integer | - | Board ID to query (required) |
| `columns` | Array | `nil` | Column filtering criteria (mutually exclusive with cursor) |
| `limit` | Integer | `25` | Items per page (max: 500) |
| `cursor` | String | `nil` | Pagination cursor (mutually exclusive with columns) |
| `select` | Array | `["id", "name"]` | Item fields to retrieve |

**Column Filter Structure:**

Each column filter is a hash with:
- `column_id` - String - The column identifier
- `column_values` - Array - Values to match (uses ANY_OF logic)

Multiple column filters use AND logic.

**Returns:** `Monday::Response`

The response contains items and cursor:

```ruby
items_page = response.body.dig("data", "items_page_by_column_values")
items = items_page["items"]
cursor = items_page["cursor"]
```

**Supported Column Types:**

Checkbox, Country, Date, Dropdown, Email, Hour, Link, Long Text, Numbers, People, Phone, Status, Text, Timeline, World Clock

**Example:**

```ruby
# Filter by single column
# Note: Use your board's actual column IDs (not titles)
response = client.item.page_by_column_values(
  board_id: 123456,
  columns: [
    { column_id: "status", column_values: ["Done", "Working on it"] }  # Your status column ID
  ],
  limit: 50
)

items_page = response.body.dig("data", "items_page_by_column_values")
items = items_page["items"]
cursor = items_page["cursor"]

# Filter by multiple columns (AND logic)
response = client.item.page_by_column_values(
  board_id: 123456,
  columns: [
    { column_id: "status", column_values: ["Done"] },  # Your status column ID
    { column_id: "text", column_values: ["High Priority"] }  # Your text column ID
  ]
)

# Next page using cursor
response = client.item.page_by_column_values(
  board_id: 123456,
  cursor: cursor
)
```

**GraphQL:** `query { items_page_by_column_values { cursor items { ... } } }`

**See:**
- [monday.com items_page_by_column_values](https://developer.monday.com/api-reference/reference/items-page-by-column-values)
- [Pagination guide](/guides/advanced/pagination)

## Response Structure

All methods return a `Monday::Response` object. Access data using:

```ruby
response.success?  # => true/false
response.status    # => 200
response.body      # => Hash with GraphQL response
```

### Typical Response Pattern

```ruby
response = client.item.query(args: { ids: [123456] })

if response.success?
  items = response.body.dig("data", "items")
  # Work with items
else
  # Handle error
end
```

## Constants

### DEFAULT_SELECT

Default fields returned by `query`, `create`, and `duplicate`:

```ruby
["id", "name", "created_at"]
```

### DEFAULT_PAGINATED_SELECT

Default fields returned by `page_by_column_values`:

```ruby
["id", "name"]
```

## Error Handling

Common errors when working with items:

- `Monday::AuthorizationError` - Invalid or missing API token
- `Monday::InvalidRequestError` - Invalid board_id or item_id
- `Monday::Error` - Invalid field requested or other API errors

See the [Error Handling guide](/guides/advanced/errors) for more details.

## Related Resources

- [Board](/reference/resources/board) - Item parent boards
- [Column](/reference/resources/column) - Item column values
- [Group](/reference/resources/group) - Item groups
- [Subitem](/reference/resources/subitem) - Item subitems

## External References

- [monday.com Items API](https://developer.monday.com/api-reference/reference/items)
- [GraphQL API Overview](https://developer.monday.com/api-reference/docs/introduction-to-graphql)
