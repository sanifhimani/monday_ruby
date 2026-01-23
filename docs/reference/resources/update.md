# Update

Access and manage updates (comments) via the `client.update` resource.

:::tip What are Updates?
Updates are comments or posts made on items in monday.com. They appear in the item's updates section and can include text, mentions, and attachments.
:::

## Methods

### query

Retrieves updates from your account.

```ruby
client.update.query(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Query arguments (see [updates query](https://developer.monday.com/api-reference/reference/updates#queries)) |
| `select` | Array | `["id", "body", "created_at"]` | Fields to retrieve |

**Returns:** `Monday::Response`

**Common args:**
- `ids` - Array of update IDs to retrieve
- `limit` - Number of results (default: 25)
- `page` - Page number

**Example:**

```ruby
response = client.update.query(
  args: { limit: 10 },
  select: ["id", "body", "created_at", "creator { id name }"]
)

updates = response.body.dig("data", "updates")
updates.each do |update|
  puts "#{update.dig('creator', 'name')}: #{update['body']}"
end
```

**GraphQL:** `query { updates { ... } }`

**See:** [monday.com updates query](https://developer.monday.com/api-reference/reference/updates#queries)

### create

Creates a new update (comment) on an item.

```ruby
client.update.create(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Creation arguments (required) |
| `select` | Array | `["id", "body", "created_at"]` | Fields to retrieve |

**Required args:**
- `item_id` - Integer or String - Item to add update to
- `body` - String - Update text content

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.update.create(
  args: {
    item_id: 123456,
    body: "This is a comment on the item"
  }
)

update = response.body.dig("data", "create_update")
# => {"id"=>"3325555116", "body"=>"This is a comment on the item", "created_at"=>"2024-07-25T03:46:49Z"}
```

**GraphQL:** `mutation { create_update { ... } }`

**See:** [monday.com create_update](https://developer.monday.com/api-reference/reference/updates#create-update)

### like

Likes an update.

```ruby
client.update.like(args: {}, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Arguments (required) |
| `select` | Array | `["id"]` | Fields to retrieve |

**Required args:**
- `update_id` - Integer or String - Update ID to like

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.update.like(
  args: { update_id: 3325555116 }
)

liked_update = response.body.dig("data", "like_update")
# => {"id"=>"221186448"}
```

**GraphQL:** `mutation { like_update { ... } }`

**See:** [monday.com like_update](https://developer.monday.com/api-reference/reference/updates#like-update)

### clear_item_updates

Clears all updates from an item.

```ruby
client.update.clear_item_updates(args: {}, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Arguments (required) |
| `select` | Array | `["id"]` | Fields to retrieve |

**Required args:**
- `item_id` - Integer or String - Item to clear updates from

**Returns:** `Monday::Response`

:::warning Destructive Operation
This permanently deletes all updates from the item. This cannot be undone.
:::

**Example:**

```ruby
response = client.update.clear_item_updates(
  args: { item_id: 123456 }
)

result = response.body.dig("data", "clear_item_updates")
# => {"id"=>"123456"}
```

**GraphQL:** `mutation { clear_item_updates { ... } }`

**See:** [monday.com clear_item_updates](https://developer.monday.com/api-reference/reference/updates#clear-item-updates)

### delete

Permanently deletes an update.

```ruby
client.update.delete(args: {}, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Arguments (required) |
| `select` | Array | `["id"]` | Fields to retrieve |

**Required args:**
- `id` - Integer or String - Update ID to delete

**Returns:** `Monday::Response`

:::warning Permanent Deletion
This operation cannot be undone. The update will be permanently deleted.
:::

**Example:**

```ruby
response = client.update.delete(
  args: { id: 3325555116 }
)

deleted_update = response.body.dig("data", "delete_update")
# => {"id"=>"3325555116"}
```

**GraphQL:** `mutation { delete_update { ... } }`

**See:** [monday.com delete_update](https://developer.monday.com/api-reference/reference/updates#delete-update)

## Response Structure

All methods return a `Monday::Response` object. Access data using:

```ruby
response.success?  # => true/false
response.status    # => 200
response.body      # => Hash with GraphQL response
```

### Typical Response Pattern

```ruby
response = client.update.create(
  args: {
    item_id: 123456,
    body: "Status update"
  }
)

if response.success?
  update = response.body.dig("data", "create_update")
  # Work with update
else
  # Handle error
end
```

## Constants

### DEFAULT_SELECT

Default fields returned by `query` and `create`:

```ruby
["id", "body", "created_at"]
```

## Error Handling

Common errors when working with updates:

- `Monday::AuthorizationError` - Invalid or missing API token
- `Monday::InvalidRequestError` - Invalid item_id or update_id
- `Monday::Error` - Invalid field requested or other API errors

See the [Error Handling guide](/guides/advanced/errors) for more details.

## External References

- [monday.com Updates API](https://developer.monday.com/api-reference/reference/updates)
- [GraphQL API Overview](https://developer.monday.com/api-reference/docs/introduction-to-graphql)
