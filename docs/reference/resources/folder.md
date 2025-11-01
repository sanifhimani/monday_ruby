# Folder

Access and manage folders via the `client.folder` resource.

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>What are Folders?</span>
Folders help organize boards within workspaces. They act as containers that group related boards together, making it easier to navigate and structure your monday.com workspace. Each folder must belong to a workspace.
:::

## Methods

### query

Retrieves folders from your account.

```ruby
client.folder.query(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Query arguments (see [folders query](https://developer.monday.com/api-reference/reference/folders#queries)) |
| `select` | Array | `["id", "name"]` | Fields to retrieve |

**Returns:** `Monday::Response`

**Common args:**
- `ids` - Array of folder IDs
- `workspace_ids` - Array of workspace IDs to filter folders

**Example:**

```ruby
response = client.folder.query(
  select: ["id", "name", "color", "created_at"]
)

folders = response.body.dig("data", "folders")

folders.each do |folder|
  puts "#{folder['name']} (ID: #{folder['id']})"
end
```

**GraphQL:** `query { folders { ... } }`

**See:** [monday.com folders query](https://developer.monday.com/api-reference/reference/folders#queries)

### create

Creates a new folder within a workspace.

```ruby
client.folder.create(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Creation arguments (required) |
| `select` | Array | `["id", "name"]` | Fields to retrieve |

**Required args:**
- `workspace_id` - Integer or String - Workspace to create folder in
- `name` - String - Folder name

**Optional args:**
- `color` - String - Folder color (hex code or color name)
- `parent_folder_id` - Integer - Create as subfolder of another folder

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.folder.create(
  args: {
    workspace_id: 8529962,
    name: "Database boards"
  }
)

folder = response.body.dig("data", "create_folder")
# => {"id"=>"15476755", "name"=>"Database boards"}

puts "Created folder: #{folder['name']}"
puts "Folder ID: #{folder['id']}"
```

**With custom fields:**

```ruby
response = client.folder.create(
  args: {
    workspace_id: 8529962,
    name: "Q1 Projects",
    color: "#FF5AC4"
  },
  select: ["id", "name", "color"]
)

folder = response.body.dig("data", "create_folder")
```

**GraphQL:** `mutation { create_folder { ... } }`

**See:** [monday.com create_folder](https://developer.monday.com/api-reference/reference/folders#create-folder)

### update

Updates a folder's attributes.

```ruby
client.folder.update(args: {}, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Update arguments (required) |
| `select` | Array | `["id"]` | Fields to retrieve |

**Required args:**
- `folder_id` - Integer or String - Folder to update
- One or more update fields:
  - `name` - String - New folder name
  - `color` - String - New folder color
  - `parent_folder_id` - Integer - Move to different parent folder

**Returns:** `Monday::Response`

**Example:**

```ruby
response = client.folder.update(
  args: {
    folder_id: 15476750,
    name: "Cool boards"
  }
)

folder = response.body.dig("data", "update_folder")
# => {"id"=>"15476750"}

puts "Updated folder ID: #{folder['id']}"
```

**Update multiple attributes:**

```ruby
response = client.folder.update(
  args: {
    folder_id: 15476750,
    name: "Updated Projects",
    color: "#00C875"
  },
  select: ["id", "name", "color"]
)

folder = response.body.dig("data", "update_folder")
```

**GraphQL:** `mutation { update_folder { ... } }`

**See:** [monday.com update_folder](https://developer.monday.com/api-reference/reference/folders#update-folder)

### delete

Permanently deletes a folder.

```ruby
client.folder.delete(args: {}, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Deletion arguments (required) |
| `select` | Array | `["id"]` | Fields to retrieve |

**Required args:**
- `folder_id` - Integer or String - Folder to delete

**Returns:** `Monday::Response`

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Permanent Deletion</span>
This operation cannot be undone. All boards in the folder will be moved to the workspace root, not deleted.
:::

**Example:**

```ruby
response = client.folder.delete(
  args: { folder_id: 15476753 }
)

folder = response.body.dig("data", "delete_folder")
# => {"id"=>"15476753"}

puts "Deleted folder ID: #{folder['id']}"
```

**GraphQL:** `mutation { delete_folder { ... } }`

**See:** [monday.com delete_folder](https://developer.monday.com/api-reference/reference/folders#delete-folder)

## Response Structure

All methods return a `Monday::Response` object. Access data using:

```ruby
response.success?  # => true/false
response.status    # => 200
response.body      # => Hash with GraphQL response
```

### Typical Response Pattern

```ruby
response = client.folder.query

if response.success?
  folders = response.body.dig("data", "folders")
  # Work with folders
else
  # Handle error
end
```

## Constants

### DEFAULT_SELECT

Default fields returned by `query` and `create`:

```ruby
["id", "name"]
```

## Error Handling

Common errors when working with folders:

- `Monday::AuthorizationError` - Invalid or missing API token
- `Monday::ResourceNotFoundError` - Folder with given ID not found
- `Monday::Error` - Invalid field requested, invalid workspace_id, or other API errors

**Example:**

```ruby
begin
  response = client.folder.delete(
    args: { folder_id: 999999 }
  )

  if response.success?
    puts "Folder deleted"
  end
rescue Monday::ResourceNotFoundError
  puts "Folder not found"
rescue Monday::AuthorizationError
  puts "Invalid API token"
rescue Monday::Error => e
  puts "Error: #{e.message}"
end
```

## Use Cases

### Organize Workspace Boards

Use folders to group related boards:

```ruby
# Create folders for different departments
departments = ["Engineering", "Marketing", "Sales", "HR"]
workspace_id = 8529962

departments.each do |dept|
  response = client.folder.create(
    args: {
      workspace_id: workspace_id,
      name: dept
    }
  )

  if response.success?
    folder = response.body.dig("data", "create_folder")
    puts "Created #{dept} folder: #{folder['id']}"
  end
end
```

### List Workspace Structure

Query all folders to understand workspace organization:

```ruby
response = client.folder.query(
  select: [
    "id",
    "name",
    "color",
    "created_at",
    {
      workspace: ["id", "name"]
    }
  ]
)

if response.success?
  folders = response.body.dig("data", "folders")

  folders.each do |folder|
    workspace_name = folder.dig("workspace", "name")
    puts "#{folder['name']} → #{workspace_name}"
  end
end
```

### Rename and Color-Code Folders

Update folder appearance:

```ruby
folder_id = 15476750

response = client.folder.update(
  args: {
    folder_id: folder_id,
    name: "Active Projects",
    color: "#00C875"  # Green
  },
  select: ["id", "name", "color"]
)

if response.success?
  folder = response.body.dig("data", "update_folder")
  puts "Updated: #{folder['name']} (#{folder['color']})"
end
```

### Clean Up Empty Folders

Delete folders that are no longer needed:

```ruby
# Query folder with boards to check if empty
response = client.folder.query(
  select: [
    "id",
    "name",
    {
      children: ["id", "name"]
    }
  ]
)

if response.success?
  folders = response.body.dig("data", "folders")

  folders.each do |folder|
    if folder["children"].nil? || folder["children"].empty?
      delete_response = client.folder.delete(
        args: { folder_id: folder["id"] }
      )

      puts "Deleted empty folder: #{folder['name']}" if delete_response.success?
    end
  end
end
```

## Related Resources

- [Board](/reference/resources/board) - Boards within folders
- [Workspace](/reference/resources/workspace) - Folder parent workspaces

## External References

- [monday.com Folders API](https://developer.monday.com/api-reference/reference/folders)
- [GraphQL API Overview](https://developer.monday.com/api-reference/docs/introduction-to-graphql)
