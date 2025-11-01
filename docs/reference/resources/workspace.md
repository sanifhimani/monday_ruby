# Workspace

Access and manage workspaces via the `client.workspace` resource.

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>What are Workspaces?</span>
Workspaces are the highest level of organization in monday.com. They group related boards together and control access permissions. Think of them as team spaces or departmental hubs where you organize boards by project, team, or purpose.
:::

## Methods

### query

Retrieves workspaces from your account.

```ruby
client.workspace.query(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Query arguments (see [workspaces query](https://developer.monday.com/api-reference/reference/workspaces#queries)) |
| `select` | Array | `["id", "name", "description"]` | Fields to retrieve |

**Returns:** `Monday::Response`

**Common args:**
- `ids` - Array of workspace IDs
- `limit` - Number of results to return
- `page` - Page number for pagination
- `state` - Workspace state (`:active`, `:archived`, `:deleted`, or `:all`)

**Example:**

```ruby
response = client.workspace.query(
  select: ["id", "name", "description"]
)

workspaces = response.body.dig("data", "workspaces")
# => [{"id"=>"7451845", "name"=>"Test Workspace", "description"=>"A test workspace"}, ...]
```

**With specific IDs:**

```ruby
response = client.workspace.query(
  args: { ids: [123, 456] },
  select: ["id", "name"]
)
```

**GraphQL:** `query { workspaces { ... } }`

**See:** [monday.com workspaces query](https://developer.monday.com/api-reference/reference/workspaces#queries)

### create

Creates a new workspace.

```ruby
client.workspace.create(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Creation arguments (required) |
| `select` | Array | `["id", "name", "description"]` | Fields to retrieve |

**Required args:**
- `name` - String (workspace name)
- `kind` - Symbol (`:open` or `:closed`)

**Optional args:**
- `description` - String (workspace description)

**Workspace kinds:**
- `:open` - Open workspace (visible to all account members)
- `:closed` - Closed workspace (visible only to workspace members)

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.workspace.create(
  args: {
    name: "Product Team",
    kind: :open,
    description: "Workspace for product development"
  }
)

workspace = response.body.dig("data", "create_workspace")
# => {"id"=>"7451865", "name"=>"Product Team", "description"=>"Workspace for product development"}
```

**GraphQL:** `mutation { create_workspace { ... } }`

**See:** [monday.com create_workspace](https://developer.monday.com/api-reference/reference/workspaces#create-workspace)

### delete

Permanently deletes a workspace.

```ruby
client.workspace.delete(workspace_id, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `workspace_id` | Integer | - | Workspace ID to delete (required) |
| `select` | Array | `["id"]` | Fields to retrieve |

**Returns:** `Monday::Response`

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Permanent Deletion</span>
This operation cannot be undone. The workspace and all its boards will be permanently deleted.
:::

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Note: Unique Method Signature</span>
Unlike most resource methods, `delete` takes `workspace_id` as a positional parameter rather than in an `args` hash.
:::

**Example:**

```ruby
response = client.workspace.delete(7451868)

workspace = response.body.dig("data", "delete_workspace")
# => {"id"=>"7451868"}
```

**GraphQL:** `mutation { delete_workspace { ... } }`

**See:** [monday.com delete_workspace](https://developer.monday.com/api-reference/reference/workspaces#delete-workspace)

## Response Structure

All methods return a `Monday::Response` object. Access data using:

```ruby
response.success?  # => true/false
response.status    # => 200
response.body      # => Hash with GraphQL response
```

### Typical Response Pattern

```ruby
response = client.workspace.query

if response.success?
  workspaces = response.body.dig("data", "workspaces")
  # Work with workspaces
else
  # Handle error
end
```

## Constants

### DEFAULT_SELECT

Default fields returned by `query` and `create`:

```ruby
["id", "name", "description"]
```

## Error Handling

See the [Error Handling guide](/guides/advanced/errors) for common errors and how to handle them.

### Common Errors

**Invalid Workspace ID:**

```ruby
begin
  client.workspace.delete(123)
rescue Monday::InvalidRequestError => e
  puts "Workspace not found: #{e.message}"
  # => "InvalidWorkspaceIdException: ..."
end
```

**Invalid Workspace Kind:**

```ruby
begin
  client.workspace.create(
    args: { name: "Test", kind: "public" }  # Wrong: String instead of Symbol
  )
rescue Monday::Error => e
  puts "Invalid kind: #{e.message}"
end
```

## Related Resources

- [Board](/reference/resources/board) - Workspace boards
- [Folder](/reference/resources/folder) - Workspace folders

## External References

- [monday.com Workspaces API](https://developer.monday.com/api-reference/reference/workspaces)
- [GraphQL API Overview](https://developer.monday.com/api-reference/docs/introduction-to-graphql)
