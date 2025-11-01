# Manage Folders

Organize boards into folders within workspaces for better structure and navigation.

## Query Folders

List all folders in your account:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.folder.query

if response.success?
  folders = response.body.dig("data", "folders")

  puts "Folders in your account:"
  folders.each do |folder|
    puts "  • #{folder['name']} (ID: #{folder['id']})"
  end
else
  puts "Failed to retrieve folders"
end
```

**Output:**
```
Folders in your account:
  • LE Development Team (ID: 10918734)
  • CRM (ID: 10977318)
  • Projects (ID: 12772091)
  • Documentation (ID: 13201660)
```

### Query Specific Folders

Retrieve folders by ID:

```ruby
response = client.folder.query(
  args: { ids: [10918734, 10977318] },
  select: ["id", "name", "color"]
)

if response.success?
  folders = response.body.dig("data", "folders")

  folders.each do |folder|
    puts "#{folder['name']}: #{folder['color']}"
  end
end
```

### Get Folder Details

Query with nested fields to see folder contents:

```ruby
response = client.folder.query(
  select: [
    "id",
    "name",
    "color",
    "created_at",
    {
      workspace: ["id", "name"],
      children: ["id", "name", "type"]
    }
  ]
)

if response.success?
  folders = response.body.dig("data", "folders")

  folders.first(3).each do |folder|
    workspace_name = folder.dig("workspace", "name")
    board_count = folder["children"]&.count || 0

    puts "\n#{folder['name']}"
    puts "  Workspace: #{workspace_name}"
    puts "  Boards: #{board_count}"
    puts "  Created: #{folder['created_at']}"
  end
end
```

**Output:**
```
LE Development Team
  Workspace: Main Workspace
  Boards: 5
  Created: 2024-01-15T10:30:00Z

CRM
  Workspace: Sales Workspace
  Boards: 3
  Created: 2024-02-20T14:22:00Z
```

## Create a Folder

Create a new folder within a workspace:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# First, get your workspace ID
workspace_response = client.workspace.query(
  select: ["id", "name"]
)

workspace = workspace_response.body.dig("data", "workspaces", 0)
workspace_id = workspace["id"]

# Create folder in that workspace
response = client.folder.create(
  args: {
    workspace_id: workspace_id,
    name: "Database boards"
  }
)

if response.success?
  folder = response.body.dig("data", "create_folder")
  puts "✓ Created folder: #{folder['name']}"
  puts "  ID: #{folder['id']}"
else
  puts "✗ Failed to create folder"
end
```

**Output:**
```
✓ Created folder: Database boards
  ID: 15476755
```

### Create with Color

Add a color to help visually identify folders:

```ruby
response = client.folder.create(
  args: {
    workspace_id: 8529962,
    name: "Q1 2024 Projects",
    color: "#FF5AC4"  # Pink
  },
  select: ["id", "name", "color"]
)

if response.success?
  folder = response.body.dig("data", "create_folder")
  puts "Created #{folder['name']} with color #{folder['color']}"
end
```

**Common colors:**
```ruby
colors = {
  red: "#E2445C",
  orange: "#FDAB3D",
  yellow: "#FFCB00",
  green: "#00C875",
  blue: "#0086C0",
  purple: "#A25DDC",
  pink: "#FF5AC4",
  gray: "#C4C4C4"
}

response = client.folder.create(
  args: {
    workspace_id: 8529962,
    name: "Engineering",
    color: colors[:blue]
  }
)
```

### Create Multiple Folders

Organize workspace with multiple folders:

```ruby
workspace_id = 8529962
folders = ["Design", "Engineering", "Marketing", "Sales"]

folders.each do |folder_name|
  response = client.folder.create(
    args: {
      workspace_id: workspace_id,
      name: folder_name
    }
  )

  if response.success?
    folder = response.body.dig("data", "create_folder")
    puts "✓ Created: #{folder['name']}"
  else
    puts "✗ Failed to create: #{folder_name}"
  end

  # Rate limiting: pause between requests
  sleep(0.3)
end
```

**Output:**
```
✓ Created: Design
✓ Created: Engineering
✓ Created: Marketing
✓ Created: Sales
```

### Create Subfolder

Create a folder within another folder:

```ruby
# Create parent folder first
parent_response = client.folder.create(
  args: {
    workspace_id: 8529962,
    name: "Projects"
  }
)

parent_id = parent_response.body.dig("data", "create_folder", "id")

# Create subfolder
response = client.folder.create(
  args: {
    workspace_id: 8529962,
    name: "Active Projects",
    parent_folder_id: parent_id
  }
)

if response.success?
  subfolder = response.body.dig("data", "create_folder")
  puts "Created subfolder: #{subfolder['name']}"
end
```

## Update Folder Name

Rename an existing folder:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.folder.update(
  args: {
    folder_id: 15476750,
    name: "Cool boards"
  }
)

if response.success?
  folder = response.body.dig("data", "update_folder")
  puts "✓ Updated folder ID: #{folder['id']}"
else
  puts "✗ Failed to update folder"
end
```

### Update Folder Color

Change the folder's visual appearance:

```ruby
response = client.folder.update(
  args: {
    folder_id: 15476750,
    color: "#00C875"  # Green
  },
  select: ["id", "name", "color"]
)

if response.success?
  folder = response.body.dig("data", "update_folder")
  puts "Updated #{folder['name']} to #{folder['color']}"
end
```

### Update Multiple Attributes

Change both name and color:

```ruby
response = client.folder.update(
  args: {
    folder_id: 15476750,
    name: "Completed Projects",
    color: "#C4C4C4"  # Gray
  },
  select: ["id", "name", "color"]
)

if response.success?
  folder = response.body.dig("data", "update_folder")
  puts "✓ Updated folder:"
  puts "  Name: #{folder['name']}"
  puts "  Color: #{folder['color']}"
end
```

### Move Folder to Different Parent

Reorganize folder hierarchy:

```ruby
# Move folder to different parent
response = client.folder.update(
  args: {
    folder_id: 15476750,
    parent_folder_id: 12345678  # New parent folder ID
  }
)

if response.success?
  puts "Folder moved to new parent"
end

# Move folder to workspace root (remove from parent)
response = client.folder.update(
  args: {
    folder_id: 15476750,
    parent_folder_id: nil
  }
)
```

## Delete Folders

Remove folders that are no longer needed:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.folder.delete(
  args: { folder_id: 15476753 }
)

if response.success?
  folder = response.body.dig("data", "delete_folder")
  puts "✓ Deleted folder ID: #{folder['id']}"
else
  puts "✗ Failed to delete folder"
end
```

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Boards Are Preserved</span>
Deleting a folder does NOT delete the boards inside it. Boards are moved to the workspace root.
:::

### Delete Multiple Folders

Clean up several folders at once:

```ruby
folder_ids = [15476753, 15476754, 15476755]

folder_ids.each do |folder_id|
  response = client.folder.delete(
    args: { folder_id: folder_id }
  )

  if response.success?
    puts "✓ Deleted folder #{folder_id}"
  else
    puts "✗ Failed to delete folder #{folder_id}"
  end

  sleep(0.3)
end
```

### Safely Delete Empty Folders

Check if folder is empty before deleting:

```ruby
# Query folder with children
response = client.folder.query(
  select: [
    "id",
    "name",
    {
      children: ["id"]
    }
  ]
)

if response.success?
  folders = response.body.dig("data", "folders")

  folders.each do |folder|
    children_count = folder["children"]&.count || 0

    if children_count == 0
      delete_response = client.folder.delete(
        args: { folder_id: folder["id"] }
      )

      if delete_response.success?
        puts "✓ Deleted empty folder: #{folder['name']}"
      end
    else
      puts "⊘ Skipped #{folder['name']} (#{children_count} boards)"
    end
  end
end
```

## Error Handling

Handle common folder operation errors:

```ruby
def create_folder_safe(client, workspace_id, name)
  response = client.folder.create(
    args: {
      workspace_id: workspace_id,
      name: name
    }
  )

  if response.success?
    folder = response.body.dig("data", "create_folder")
    puts "✓ Created: #{folder['name']} (ID: #{folder['id']})"
    folder['id']
  else
    puts "✗ Failed to create folder: #{name}"
    puts "  Status: #{response.status}"

    if response.body["errors"]
      response.body["errors"].each do |error|
        puts "  Error: #{error['message']}"
      end
    end

    nil
  end
rescue Monday::AuthorizationError
  puts "✗ Invalid API token"
  nil
rescue Monday::Error => e
  puts "✗ API error: #{e.message}"
  nil
end

# Usage
folder_id = create_folder_safe(client, 8529962, "New Folder")
```

### Handle Delete Errors

Gracefully handle non-existent folders:

```ruby
def delete_folder_safe(client, folder_id)
  response = client.folder.delete(
    args: { folder_id: folder_id }
  )

  if response.success?
    puts "✓ Deleted folder #{folder_id}"
    true
  else
    puts "✗ Failed to delete folder #{folder_id}"
    false
  end
rescue Monday::ResourceNotFoundError
  puts "✗ Folder #{folder_id} not found"
  false
rescue Monday::AuthorizationError
  puts "✗ Invalid API token"
  false
rescue Monday::Error => e
  puts "✗ Error: #{e.message}"
  false
end

# Usage
delete_folder_safe(client, 999999)  # Non-existent folder
```

### Validate Before Update

Check folder exists before updating:

```ruby
def update_folder_safe(client, folder_id, updates)
  # First verify folder exists
  query_response = client.folder.query(
    args: { ids: [folder_id] },
    select: ["id", "name"]
  )

  folders = query_response.body.dig("data", "folders") || []

  if folders.empty?
    puts "✗ Folder #{folder_id} not found"
    return false
  end

  # Folder exists, proceed with update
  response = client.folder.update(
    args: updates.merge(folder_id: folder_id)
  )

  if response.success?
    puts "✓ Updated folder #{folder_id}"
    true
  else
    puts "✗ Failed to update folder"
    false
  end
rescue Monday::Error => e
  puts "✗ Error: #{e.message}"
  false
end

# Usage
update_folder_safe(client, 15476750, { name: "New Name" })
```

## Complete Example

Full workflow for managing folders:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# 1. Get workspace
workspace_response = client.workspace.query(
  select: ["id", "name"]
)

workspace = workspace_response.body.dig("data", "workspaces", 0)
workspace_id = workspace["id"]

puts "Working in workspace: #{workspace['name']}"
puts "#{'=' * 50}"

# 2. Create new folder
create_response = client.folder.create(
  args: {
    workspace_id: workspace_id,
    name: "Q1 2024 Projects",
    color: "#00C875"
  },
  select: ["id", "name", "color"]
)

if create_response.success?
  folder = create_response.body.dig("data", "create_folder")

  puts "\n✓ Created Folder"
  puts "  ID: #{folder['id']}"
  puts "  Name: #{folder['name']}"
  puts "  Color: #{folder['color']}"

  folder_id = folder["id"]

  # 3. Update folder name after creation
  sleep(1)  # Brief pause

  update_response = client.folder.update(
    args: {
      folder_id: folder_id,
      name: "Q1 2024 Active Projects"
    },
    select: ["id", "name"]
  )

  if update_response.success?
    puts "\n✓ Updated Folder Name"
    puts "  ID: #{folder_id}"
    puts "  New Name: Q1 2024 Active Projects"
  end

  # 4. Query the folder to verify
  sleep(1)

  query_response = client.folder.query(
    args: { ids: [folder_id] },
    select: [
      "id",
      "name",
      "color",
      {
        workspace: ["id", "name"]
      }
    ]
  )

  if query_response.success?
    queried_folder = query_response.body.dig("data", "folders", 0)

    puts "\n✓ Verified Folder"
    puts "  Name: #{queried_folder['name']}"
    puts "  Color: #{queried_folder['color']}"
    puts "  Workspace: #{queried_folder.dig('workspace', 'name')}"
  end

  # 5. Clean up - delete the folder
  sleep(1)

  delete_response = client.folder.delete(
    args: { folder_id: folder_id }
  )

  if delete_response.success?
    puts "\n✓ Deleted Folder"
    puts "  ID: #{folder_id}"
  end

  puts "\n#{'=' * 50}"
  puts "Folder lifecycle complete!"
else
  puts "\n✗ Failed to create folder"
end
```

**Output:**
```
Working in workspace: Main Workspace
==================================================

✓ Created Folder
  ID: 15476755
  Name: Q1 2024 Projects
  Color: #00C875

✓ Updated Folder Name
  ID: 15476755
  New Name: Q1 2024 Active Projects

✓ Verified Folder
  Name: Q1 2024 Active Projects
  Color: #00C875
  Workspace: Main Workspace

✓ Deleted Folder
  ID: 15476755

==================================================
Folder lifecycle complete!
```

## Organize Workspace Structure

Create a complete folder hierarchy:

```ruby
workspace_id = 8529962

# Create department folders with color coding
departments = {
  "Engineering" => "#0086C0",    # Blue
  "Product" => "#A25DDC",        # Purple
  "Marketing" => "#FF5AC4",      # Pink
  "Sales" => "#00C875",          # Green
  "Operations" => "#FDAB3D"      # Orange
}

created_folders = []

departments.each do |name, color|
  response = client.folder.create(
    args: {
      workspace_id: workspace_id,
      name: name,
      color: color
    },
    select: ["id", "name", "color"]
  )

  if response.success?
    folder = response.body.dig("data", "create_folder")
    created_folders << folder
    puts "✓ Created #{folder['name']} (#{folder['color']})"
  end

  sleep(0.3)
end

puts "\nCreated #{created_folders.count} department folders"

# Create project folders within Engineering
engineering_folder = created_folders.find { |f| f["name"] == "Engineering" }

if engineering_folder
  projects = ["Backend API", "Frontend App", "Mobile App"]

  projects.each do |project|
    response = client.folder.create(
      args: {
        workspace_id: workspace_id,
        name: project,
        parent_folder_id: engineering_folder["id"]
      }
    )

    puts "  ✓ Created #{project}" if response.success?
    sleep(0.3)
  end
end
```

## Next Steps

- [Create boards](/guides/boards/create)
- [Query boards](/guides/boards/query)
- [Board API reference](/reference/resources/board)
- [Folder API reference](/reference/resources/folder)
