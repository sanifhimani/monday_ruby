# Board

Access and manage boards via the `client.board` resource.

## Methods

### query

Retrieves boards from your account.

```ruby
client.board.query(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Query arguments (see [boards query](https://developer.monday.com/api-reference/reference/boards#queries)) |
| `select` | Array | `["id", "name", "description"]` | Fields to retrieve |

**Returns:** `Monday::Response`

**Common args:**
- `ids` - Array of board IDs
- `limit` - Number of results (default: 25)
- `page` - Page number
- `state` - `:active`, `:archived`, `:deleted`, or `:all`
- `board_kind` - `:public`, `:private`, or `:share`
- `workspace_ids` - Array of workspace IDs
- `order_by` - `:created_at` or `:used_at`

**Example:**

```ruby
response = client.board.query(
  args: { ids: [123, 456], state: :active },
  select: ["id", "name", "url"]
)

boards = response.body.dig("data", "boards")
```

**GraphQL:** `query { boards { ... } }`

**See:** [monday.com boards query](https://developer.monday.com/api-reference/reference/boards#queries)

### create

Creates a new board.

```ruby
client.board.create(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Creation arguments (required) |
| `select` | Array | `["id", "name", "description"]` | Fields to retrieve |

**Required args:**
- `board_name` - String
- `board_kind` - Symbol (`:public`, `:private`, or `:share`)

**Optional args:**
- `description` - String
- `workspace_id` - Integer
- `folder_id` - Integer
- `template_id` - Integer

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.board.create(
  args: {
    board_name: "New Board",
    board_kind: :public
  }
)

board = response.body.dig("data", "create_board")
```

**GraphQL:** `mutation { create_board { ... } }`

**See:** [monday.com create_board](https://developer.monday.com/api-reference/reference/boards#create-board)

### update

Updates a board's attributes.

```ruby
client.board.update(args: {})
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Update arguments (required) |

**Required args:**
- `board_id` - Integer
- `board_attribute` - Symbol (`:name`, `:description`, or `:communication`)
- `new_value` - String

**Returns:** `Monday::Response`

The response body contains a JSON string at `response.body["data"]["update_board"]` that must be parsed:

```ruby
result = JSON.parse(response.body["data"]["update_board"])
# => { "success" => true, "undo_data" => "..." }
```

**Example:**

```ruby
response = client.board.update(
  args: {
    board_id: 123,
    board_attribute: :name,
    new_value: "Updated Name"
  }
)

result = JSON.parse(response.body["data"]["update_board"])
```

**GraphQL:** `mutation { update_board { ... } }`

**See:** [monday.com update_board](https://developer.monday.com/api-reference/reference/boards#update-board)

### duplicate

Duplicates an existing board.

```ruby
client.board.duplicate(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Duplication arguments (required) |
| `select` | Array | `["id", "name", "description"]` | Fields to retrieve |

**Required args:**
- `board_id` - Integer
- `duplicate_type` - Symbol

**Duplicate types:**
- `:duplicate_board_with_structure` - Structure only
- `:duplicate_board_with_pulses` - Structure + items
- `:duplicate_board_with_pulses_and_updates` - Structure + items + updates

**Optional args:**
- `board_name` - String
- `workspace_id` - Integer
- `folder_id` - Integer
- `keep_subscribers` - Boolean

**Returns:** `Monday::Response`

The duplicated board is nested under `board`:

```ruby
board = response.body.dig("data", "duplicate_board", "board")
```

**Example:**

```ruby
response = client.board.duplicate(
  args: {
    board_id: 123,
    duplicate_type: :duplicate_board_with_structure
  }
)

board = response.body.dig("data", "duplicate_board", "board")
```

**GraphQL:** `mutation { duplicate_board { board { ... } } }`

**See:** [monday.com duplicate_board](https://developer.monday.com/api-reference/reference/boards#duplicate-board)

### archive

Archives a board.

```ruby
client.board.archive(board_id, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `board_id` | Integer | - | Board ID to archive (required) |
| `select` | Array | `["id"]` | Fields to retrieve |

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.board.archive(123)

board = response.body.dig("data", "archive_board")
```

**GraphQL:** `mutation { archive_board { ... } }`

**See:** [monday.com archive_board](https://developer.monday.com/api-reference/reference/boards#archive-board)

### delete

Permanently deletes a board.

```ruby
client.board.delete(board_id, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `board_id` | Integer | - | Board ID to delete (required) |
| `select` | Array | `["id"]` | Fields to retrieve |

**Returns:** `Monday::Response`

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Permanent Deletion</span>
This operation cannot be undone. All board data will be permanently lost.
:::

**Example:**

```ruby
response = client.board.delete(123)

board = response.body.dig("data", "delete_board")
```

**GraphQL:** `mutation { delete_board { ... } }`

**See:** [monday.com delete_board](https://developer.monday.com/api-reference/reference/boards#delete-board)

### items_page

Retrieves paginated items from a board using cursor-based pagination.

```ruby
client.board.items_page(
  board_ids:,
  limit: 25,
  cursor: nil,
  query_params: nil,
  select: DEFAULT_PAGINATED_SELECT
)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `board_ids` | Integer or Array | - | Board ID(s) to query (required) |
| `limit` | Integer | `25` | Items per page (max: 500) |
| `cursor` | String | `nil` | Pagination cursor |
| `query_params` | Hash | `nil` | Query filters with rules and operators |
| `select` | Array | `["id", "name"]` | Item fields to retrieve |

**Returns:** `Monday::Response`

The response contains items and cursor:

```ruby
items_page = response.body.dig("data", "boards", 0, "items_page")
items = items_page["items"]
cursor = items_page["cursor"]
```

**Example:**

```ruby
# First page
response = client.board.items_page(
  board_ids: 123,
  limit: 50
)

items_page = response.body.dig("data", "boards", 0, "items_page")
cursor = items_page["cursor"]

# Next page
response = client.board.items_page(
  board_ids: 123,
  cursor: cursor
)
```

**GraphQL:** `query { boards { items_page { ... } } }`

**See:**
- [monday.com items_page](https://developer.monday.com/api-reference/reference/items-page)
- [Pagination guide](/guides/advanced/pagination)

### delete_subscribers

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Deprecated</span>
This method is deprecated and will be removed in v2.0.0. Use `client.user.delete_from_board` instead.
:::

Deletes subscribers from a board.

```ruby
client.board.delete_subscribers(board_id, user_ids, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `board_id` | Integer | - | Board ID (required) |
| `user_ids` | Integer[] | - | User IDs to remove (required) |
| `select` | Array | `["id"]` | Fields to retrieve | -->

**Returns:** `Monday::Response`

**GraphQL:** `mutation { delete_subscribers_from_board { ... } }`

## Response Structure

All methods return a `Monday::Response` object. Access data using:

```ruby
response.success?  # => true/false
response.status    # => 200
response.body      # => Hash with GraphQL response
```

### Typical Response Pattern

```ruby
response = client.board.query(args: { ids: [123] })

if response.success?
  boards = response.body.dig("data", "boards")
  # Work with boards
else
  # Handle error
end
```

## Constants

### DEFAULT_SELECT

Default fields returned by `query`, `create`, and `duplicate`:

```ruby
["id", "name", "description"]
```

### DEFAULT_PAGINATED_SELECT

Default fields returned by `items_page`:

```ruby
["id", "name"]
```

## Error Handling

See the [Error Handling guide](/guides/advanced/errors) for common errors and how to handle them.

## Related Resources

- [Item](/reference/resources/item) - Board items
- [Column](/reference/resources/column) - Board columns
- [Group](/reference/resources/group) - Board groups
- [Workspace](/reference/resources/workspace) - Board workspaces

## External References

- [monday.com Boards API](https://developer.monday.com/api-reference/reference/boards)
- [GraphQL API Overview](https://developer.monday.com/api-reference/docs/introduction-to-graphql)
