# Group

Access and manage groups via the `client.group` resource.

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>What are Groups?</span>
Groups are sections within boards that organize related items together. Think of them like folders or categories that help structure your board's content. Each board can have multiple groups, and items can be moved between groups.
:::

## Methods

### query

Retrieves groups from boards.

```ruby
client.group.query(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Query arguments (board IDs, filters) |
| `select` | Array | `["id", "title"]` | Fields to retrieve |

**Returns:** `Monday::Response`

**Common args:**
- `ids` - Array of board IDs to query groups from

**Example:**

```ruby
response = client.group.query(
  args: { ids: [123, 456] },
  select: ["id", "title", "color", "position"]
)

boards = response.body.dig("data", "boards")
boards.each do |board|
  board["groups"].each do |group|
    puts "#{group['title']} (#{group['id']})"
  end
end
```

**GraphQL:** `query { boards { groups { ... } } }`

**See:** [monday.com groups query](https://developer.monday.com/api-reference/reference/groups)

### create

Creates a new group on a board.

```ruby
client.group.create(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Creation arguments (required) |
| `select` | Array | `["id", "title"]` | Fields to retrieve |

**Required args:**
- `board_id` - String or Integer - Board ID
- `group_name` - String - Name for the new group

**Optional args:**
- `position` - String - Position relative to other groups (`:first`, `:last`, or after a specific group ID)
- `position_relative_method` - Symbol - `:before_at` or `:after_at` when using position with group ID
- `relative_to` - String - Group ID to position relative to

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.group.create(
  args: {
    board_id: 123,
    group_name: "Returned Orders"
  }
)

group = response.body.dig("data", "create_group")
puts "Created group: #{group['title']} (#{group['id']})"
```

**GraphQL:** `mutation { create_group { ... } }`

**See:** [monday.com create_group](https://developer.monday.com/api-reference/reference/groups#create-group)

### update

Updates a group's attributes.

```ruby
client.group.update(args: {}, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Update arguments (required) |
| `select` | Array | `["id"]` | Fields to retrieve |

**Required args:**
- `board_id` - String or Integer - Board ID
- `group_id` - String - Group ID
- `group_attribute` - Symbol - Attribute to update (`:title`, `:color`, `:position`)
- `new_value` - String - New value for the attribute

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.group.update(
  args: {
    board_id: 123,
    group_id: "group_mkx1yn2n",
    group_attribute: :title,
    new_value: "Completed Orders"
  }
)

group = response.body.dig("data", "update_group")
```

**GraphQL:** `mutation { update_group { ... } }`

**See:** [monday.com update_group](https://developer.monday.com/api-reference/reference/groups#update-group)

### delete

Permanently deletes a group.

```ruby
client.group.delete(args: {}, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Deletion arguments (required) |
| `select` | Array | `["id"]` | Fields to retrieve |

**Required args:**
- `board_id` - String or Integer - Board ID
- `group_id` - String - Group ID to delete

**Returns:** `Monday::Response`

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Permanent Deletion</span>
Deleting a group permanently removes all items within it. This operation cannot be undone. Consider archiving instead to preserve data.
:::

**Example:**

```ruby
response = client.group.delete(
  args: {
    board_id: 123,
    group_id: "group_mkx1yn2n"
  }
)

deleted_group = response.body.dig("data", "delete_group")
```

**GraphQL:** `mutation { delete_group { ... } }`

**See:** [monday.com delete_group](https://developer.monday.com/api-reference/reference/groups#delete-group)

### archive

Archives a group (soft delete).

```ruby
client.group.archive(args: {}, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Archive arguments (required) |
| `select` | Array | `["id"]` | Fields to retrieve |

**Required args:**
- `board_id` - String or Integer - Board ID
- `group_id` - String - Group ID to archive

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.group.archive(
  args: {
    board_id: 123,
    group_id: "group_mkx1yn2n"
  }
)

archived_group = response.body.dig("data", "archive_group")
```

**GraphQL:** `mutation { archive_group { ... } }`

**See:** [monday.com archive_group](https://developer.monday.com/api-reference/reference/groups#archive-group)

### duplicate

Duplicates an existing group.

```ruby
client.group.duplicate(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Duplication arguments (required) |
| `select` | Array | `["id", "title"]` | Fields to retrieve |

**Required args:**
- `board_id` - String or Integer - Board ID
- `group_id` - String - Group ID to duplicate

**Optional args:**
- `add_to_top` - Boolean - Add duplicated group to top of board (default: false)
- `group_title` - String - Custom title for duplicated group

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.group.duplicate(
  args: {
    board_id: 123,
    group_id: "group_mkx1yn2n",
    group_title: "Copy of Returned Orders",
    add_to_top: true
  }
)

duplicated_group = response.body.dig("data", "duplicate_group")
puts "Duplicated: #{duplicated_group['title']}"
```

**GraphQL:** `mutation { duplicate_group { ... } }`

**See:** [monday.com duplicate_group](https://developer.monday.com/api-reference/reference/groups#duplicate-group)

### move_item

Moves an item to a different group.

```ruby
client.group.move_item(args: {}, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Move arguments (required) |
| `select` | Array | `["id"]` | Item fields to retrieve |

**Required args:**
- `item_id` - String or Integer - Item ID to move
- `group_id` - String - Destination group ID

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.group.move_item(
  args: {
    item_id: 987654321,
    group_id: "group_mkx1yn2n"
  },
  select: ["id", "name", "group { id title }"]
)

moved_item = response.body.dig("data", "move_item_to_group")
```

**GraphQL:** `mutation { move_item_to_group { ... } }`

**See:** [monday.com move_item_to_group](https://developer.monday.com/api-reference/reference/groups#move-item-to-group)

### items_page

Retrieves paginated items from groups using cursor-based pagination.

```ruby
client.group.items_page(
  board_ids:,
  group_ids:,
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
| `group_ids` | String or Array | - | Group ID(s) to query (required) |
| `limit` | Integer | `25` | Items per page (max: 500) |
| `cursor` | String | `nil` | Pagination cursor from previous response |
| `query_params` | Hash | `nil` | Filter items with rules and operators |
| `select` | Array | `["id", "name"]` | Item fields to retrieve |

**Returns:** `Monday::Response`

The response contains items and cursor for pagination:

```ruby
items_page = response.body.dig("data", "boards", 0, "groups", 0, "items_page")
items = items_page["items"]
cursor = items_page["cursor"]  # Use for next page, nil if no more pages
```

**Pagination:**

Cursors are temporary tokens that expire after 60 minutes. They mark your position in the result set and enable efficient pagination through large datasets.

**Query Params Structure:**

```ruby
{
  rules: [
    {
      column_id: "status",
      compare_value: [1, 2],  # Array of acceptable values
      operator: :any_of       # Optional: :any_of, :not_any_of, etc.
    }
  ],
  operator: :and  # Combines multiple rules: :and or :or
}
```

**Example - Basic Pagination:**

```ruby
# First page
response = client.group.items_page(
  board_ids: 123,
  group_ids: "group_mkx1yn2n",
  limit: 50
)

items_page = response.body.dig("data", "boards", 0, "groups", 0, "items_page")
items = items_page["items"]
cursor = items_page["cursor"]

# Next page
if cursor
  response = client.group.items_page(
    board_ids: 123,
    group_ids: "group_mkx1yn2n",
    cursor: cursor
  )
end
```

**Example - Multiple Boards and Groups:**

```ruby
response = client.group.items_page(
  board_ids: [123, 456],
  group_ids: ["group_1", "group_2"],
  limit: 100
)

boards = response.body.dig("data", "boards")
boards.each do |board|
  board["groups"].each do |group|
    items = group["items_page"]["items"]
    puts "Group #{group['items_page']['items'].length} items"
  end
end
```

**Example - Filtered Query:**

```ruby
response = client.group.items_page(
  board_ids: 123,
  group_ids: "group_mkx1yn2n",
  limit: 100,
  query_params: {
    rules: [
      { column_id: "status", compare_value: [1] }
    ],
    operator: :and
  }
)

# Only items matching the filter are returned
items = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "items")
```

**Example - Custom Fields:**

```ruby
response = client.group.items_page(
  board_ids: 123,
  group_ids: "group_mkx1yn2n",
  limit: 50,
  select: [
    "id",
    "name",
    "created_at",
    "updated_at",
    {
      column_values: ["id", "text", "value"]
    }
  ]
)
```

**GraphQL:** `query { boards { groups { items_page { ... } } } }`

**See:**
- [monday.com items_page](https://developer.monday.com/api-reference/reference/items-page)
- [Pagination guide](/guides/advanced/pagination)
- [Query params filtering](https://developer.monday.com/api-reference/reference/items-page#query-params)

## Response Structure

All methods return a `Monday::Response` object. Access data using:

```ruby
response.success?  # => true/false
response.status    # => 200
response.body      # => Hash with GraphQL response
```

### Typical Response Pattern

```ruby
response = client.group.query(args: { ids: [123] })

if response.success?
  boards = response.body.dig("data", "boards")
  boards.each do |board|
    board["groups"].each do |group|
      puts group["title"]
    end
  end
else
  # Handle error
end
```

## Constants

### DEFAULT_SELECT

Default fields returned by `query`, `create`, `duplicate`:

```ruby
["id", "title"]
```

### DEFAULT_PAGINATED_SELECT

Default fields returned by `items_page`:

```ruby
["id", "name"]
```

## Error Handling

See the [Error Handling guide](/guides/advanced/errors) for common errors and how to handle them.

**Common errors:**
- `Monday::ResourceNotFoundError` - Group or board not found
- `Monday::AuthorizationError` - Invalid permissions or token
- `Monday::InvalidRequestError` - Invalid arguments

## Related Resources

- [Item](/reference/resources/item) - Items within groups
- [Board](/reference/resources/board) - Boards containing groups
- [Column](/reference/resources/column) - Columns in groups

## External References

- [monday.com Groups API](https://developer.monday.com/api-reference/reference/groups)
- [monday.com items_page](https://developer.monday.com/api-reference/reference/items-page)
- [GraphQL API Overview](https://developer.monday.com/api-reference/docs/introduction-to-graphql)
