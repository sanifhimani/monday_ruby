# Manage Workspaces

Learn how to create, query, and delete workspaces programmatically to organize your boards and teams.

## What are Workspaces?

Workspaces are the top-level organizational structure in monday.com. They help you:
- Group related boards together (e.g., Marketing, Engineering, Sales)
- Control access permissions at the team or department level
- Organize projects by purpose, team, or initiative

## Query Workspaces

Retrieve all workspaces in your account:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.workspace.query

if response.success?
  workspaces = response.body.dig("data", "workspaces")

  puts "Your Workspaces:"
  workspaces.each do |workspace|
    puts "  • #{workspace['name']} (ID: #{workspace['id']})"
  end
end
```

**Output:**
```
Your Workspaces:
  • Product Team (ID: 7451845)
  • Marketing (ID: 7450850)
  • Main workspace (ID: 7217155)
```

### Query with Additional Fields

Get more details about your workspaces:

```ruby
response = client.workspace.query(
  select: [
    "id",
    "name",
    "description",
    "kind",
    "state",
    {
      owners_subscribers: ["id", "name", "email"]
    }
  ]
)

if response.success?
  workspaces = response.body.dig("data", "workspaces")

  workspaces.each do |workspace|
    puts "\n#{workspace['name']}"
    puts "  Description: #{workspace['description'] || 'None'}"
    puts "  Type: #{workspace['kind']}"
    puts "  State: #{workspace['state']}"
  end
end
```

### Query Specific Workspaces

Filter by workspace IDs:

```ruby
response = client.workspace.query(
  args: { ids: [7451845, 7450850] },
  select: ["id", "name", "description"]
)

if response.success?
  workspaces = response.body.dig("data", "workspaces")
  puts "Found #{workspaces.length} workspace(s)"
end
```

## Create a Workspace

### Basic Workspace Creation

Create an open workspace visible to all account members:

```ruby
response = client.workspace.create(
  args: {
    name: "Product Team",
    kind: :open
  }
)

if response.success?
  workspace = response.body.dig("data", "create_workspace")
  puts "Created workspace: #{workspace['name']}"
  puts "Workspace ID: #{workspace['id']}"
end
```

**Output:**
```
Created workspace: Product Team
Workspace ID: 7451865
```

### Create with Description

Add context to your workspace:

```ruby
response = client.workspace.create(
  args: {
    name: "Engineering",
    kind: :open,
    description: "All engineering projects and infrastructure boards"
  }
)

if response.success?
  workspace = response.body.dig("data", "create_workspace")
  puts "Created: #{workspace['name']}"
  puts "Description: #{workspace['description']}"
end
```

### Create a Closed Workspace

Create a private workspace for specific teams:

```ruby
response = client.workspace.create(
  args: {
    name: "Executive Leadership",
    kind: :closed,
    description: "Strategic planning and executive decisions"
  }
)

if response.success?
  workspace = response.body.dig("data", "create_workspace")
  puts "Created closed workspace: #{workspace['name']}"
  puts "ID: #{workspace['id']}"
end
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Workspace Kinds</span>
- **`:open`** - Visible to all account members
- **`:closed`** - Visible only to explicitly added members
:::

## Organize Boards in Workspaces

Create boards within a specific workspace:

```ruby
# First, create a workspace
workspace_response = client.workspace.create(
  args: {
    name: "Marketing Campaigns",
    kind: :open,
    description: "All marketing projects and campaigns"
  }
)

workspace_id = workspace_response.body.dig("data", "create_workspace", "id")

# Create a board in that workspace
board_response = client.board.create(
  args: {
    board_name: "Q1 2024 Campaign",
    board_kind: :public,
    workspace_id: workspace_id.to_i
  }
)

if board_response.success?
  board = board_response.body.dig("data", "create_board")
  puts "Created board '#{board['name']}' in workspace #{workspace_id}"
end
```

### Query Boards by Workspace

Find all boards in a specific workspace:

```ruby
workspace_id = 7451865

response = client.board.query(
  args: { workspace_ids: [workspace_id] },
  select: ["id", "name", "workspace_id"]
)

if response.success?
  boards = response.body.dig("data", "boards")

  puts "Boards in workspace #{workspace_id}:"
  boards.each do |board|
    puts "  • #{board['name']} (ID: #{board['id']})"
  end
end
```

## Delete a Workspace

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Permanent Deletion</span>
Deleting a workspace is irreversible. All boards within the workspace will also be deleted. Always confirm before deletion.
:::

### Basic Deletion

```ruby
workspace_id = 7451868

response = client.workspace.delete(workspace_id)

if response.success?
  deleted = response.body.dig("data", "delete_workspace")
  puts "Deleted workspace ID: #{deleted['id']}"
end
```

### Safe Deletion with Confirmation

Implement a confirmation check before deletion:

```ruby
def delete_workspace_safe(client, workspace_id)
  # First, check if workspace exists
  query_response = client.workspace.query(
    args: { ids: [workspace_id] },
    select: ["id", "name"]
  )

  workspaces = query_response.body.dig("data", "workspaces")

  if workspaces.empty?
    puts "Workspace #{workspace_id} not found"
    return false
  end

  workspace = workspaces.first
  puts "About to delete workspace: #{workspace['name']}"
  print "Type 'DELETE' to confirm: "

  confirmation = gets.chomp

  if confirmation == "DELETE"
    response = client.workspace.delete(workspace_id)

    if response.success?
      puts "Workspace deleted successfully"
      true
    else
      puts "Failed to delete workspace"
      false
    end
  else
    puts "Deletion cancelled"
    false
  end
end

# Usage
delete_workspace_safe(client, 7451868)
```

## Error Handling

Handle common workspace errors:

```ruby
def create_workspace_safe(client, name, kind, description = nil)
  response = client.workspace.create(
    args: {
      name: name,
      kind: kind,
      description: description
    }.compact
  )

  if response.success?
    workspace = response.body.dig("data", "create_workspace")
    puts "Created workspace: #{workspace['name']}"
    workspace['id']
  else
    puts "Failed to create workspace"

    if response.body["errors"]
      response.body["errors"].each do |error|
        puts "  Error: #{error['message']}"
      end
    end

    nil
  end
rescue Monday::AuthorizationError
  puts "Invalid API token"
  nil
rescue Monday::InvalidRequestError => e
  puts "Invalid request: #{e.message}"
  nil
rescue Monday::Error => e
  puts "API error: #{e.message}"
  nil
end

# Usage
workspace_id = create_workspace_safe(client, "New Workspace", :open, "Description")
```

### Handle Invalid Workspace ID

```ruby
workspace_id = 123  # Non-existent workspace

begin
  response = client.workspace.delete(workspace_id)
rescue Monday::InvalidRequestError => e
  if e.message.include?("InvalidWorkspaceIdException")
    puts "Workspace #{workspace_id} does not exist"
  else
    puts "Error: #{e.message}"
  end
end
```

## Complete Example

Full workflow for managing workspaces:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# 1. Create a new workspace
puts "1. Creating workspace..."
create_response = client.workspace.create(
  args: {
    name: "Product Development",
    kind: :open,
    description: "All product engineering and design work"
  }
)

if create_response.success?
  workspace = create_response.body.dig("data", "create_workspace")
  workspace_id = workspace["id"]

  puts "   Created: #{workspace['name']}"
  puts "   ID: #{workspace_id}"
  puts "   Description: #{workspace['description']}"

  # 2. Create boards in the workspace
  puts "\n2. Creating boards in workspace..."

  ["Backend API", "Frontend App", "Design System"].each do |board_name|
    board_response = client.board.create(
      args: {
        board_name: board_name,
        board_kind: :public,
        workspace_id: workspace_id.to_i
      }
    )

    if board_response.success?
      board = board_response.body.dig("data", "create_board")
      puts "   Created board: #{board['name']}"
    end
  end

  # 3. Query all workspaces
  puts "\n3. Listing all workspaces..."
  list_response = client.workspace.query(
    select: ["id", "name", "description"]
  )

  if list_response.success?
    workspaces = list_response.body.dig("data", "workspaces")
    workspaces.each do |ws|
      puts "   • #{ws['name']} (#{ws['id']})"
    end
  end

  # 4. Query boards in the workspace
  puts "\n4. Boards in #{workspace['name']}:"
  boards_response = client.board.query(
    args: { workspace_ids: [workspace_id.to_i] },
    select: ["id", "name"]
  )

  if boards_response.success?
    boards = boards_response.body.dig("data", "boards")
    boards.each do |board|
      puts "   • #{board['name']}"
    end
  end

  puts "\nWorkspace setup complete!"
else
  puts "Failed to create workspace"
end
```

## Best Practices

### 1. Use Descriptive Names

Choose clear, meaningful workspace names:

```ruby
# Good
client.workspace.create(args: { name: "Marketing - Q1 2024", kind: :open })
client.workspace.create(args: { name: "Engineering - Infrastructure", kind: :open })

# Avoid
client.workspace.create(args: { name: "Workspace 1", kind: :open })
client.workspace.create(args: { name: "Misc", kind: :open })
```

### 2. Add Descriptions

Always include descriptions for clarity:

```ruby
client.workspace.create(
  args: {
    name: "Customer Success",
    kind: :open,
    description: "Customer onboarding, support, and success initiatives"
  }
)
```

### 3. Choose Appropriate Privacy

Select the right workspace kind:

```ruby
# Public projects - use :open
client.workspace.create(
  args: { name: "Company Events", kind: :open }
)

# Sensitive information - use :closed
client.workspace.create(
  args: { name: "HR & Recruiting", kind: :closed }
)
```

### 4. Organize Logically

Group related boards:

```ruby
# Create workspace for a specific team
workspace = client.workspace.create(
  args: {
    name: "Sales Team",
    kind: :open,
    description: "Sales pipeline, accounts, and opportunities"
  }
)

workspace_id = workspace.body.dig("data", "create_workspace", "id").to_i

# Add related boards
["Pipeline", "Accounts", "Opportunities", "Reports"].each do |name|
  client.board.create(
    args: {
      board_name: name,
      board_kind: :public,
      workspace_id: workspace_id
    }
  )
end
```

## Next Steps

- [Create boards](/guides/boards/create) in your workspaces
- [Query boards](/guides/boards/query) by workspace
- [Manage folders](/guides/folders/manage) within workspaces
- [Organize groups](/guides/groups/manage) across boards
