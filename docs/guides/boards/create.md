# Create a Board

Create new boards programmatically in your monday.com account.

## Basic Board Creation

Create a board with just a name:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.board.create(
  args: {
    board_name: "My New Board",
    board_kind: :public
  }
)

if response.success?
  board = response.body.dig("data", "create_board")
  puts "✓ Created board: #{board['name']}"
  puts "  ID: #{board['id']}"
else
  puts "✗ Failed to create board"
end
```

**Output:**
```
✓ Created board: My New Board
  ID: 1234567890
```

## Board Privacy Levels

Specify who can access the board:

### Public Board

Visible to all workspace members:

```ruby
response = client.board.create(
  args: {
    board_name: "Team Announcements",
    board_kind: :public
  }
)
```

### Private Board

Only visible to board subscribers:

```ruby
response = client.board.create(
  args: {
    board_name: "Executive Planning",
    board_kind: :private
  }
)
```

### Shareable Board

Can be shared via link outside your workspace:

```ruby
response = client.board.create(
  args: {
    board_name: "Client Collaboration",
    board_kind: :share
  }
)
```

## Add Description

Include a board description:

```ruby
response = client.board.create(
  args: {
    board_name: "Q1 Marketing Campaign",
    board_kind: :public,
    description: "Track all marketing initiatives for Q1 2024"
  }
)

if response.success?
  board = response.body.dig("data", "create_board")
  puts "Created: #{board['name']}"
  puts "Description: #{board['description']}"
end
```

## Create from Template

Use an existing board as a template:

```ruby
template_id = 1234567890  # ID of the template board

response = client.board.create(
  args: {
    board_name: "New Project from Template",
    board_kind: :public,
    template_id: template_id
  }
)

if response.success?
  board = response.body.dig("data", "create_board")
  puts "✓ Created from template: #{board['name']}"
end
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Templates</span>
Templates copy the board structure (columns, groups, automations) but not the items. Perfect for recurring project types.
:::

## Create in Workspace

Add the board to a specific workspace:

```ruby
workspace_id = 9876543210

response = client.board.create(
  args: {
    board_name: "Product Development",
    board_kind: :public,
    workspace_id: workspace_id
  }
)
```

## Create in Folder

Organize boards by placing them in folders:

```ruby
folder_id = 5555555555

response = client.board.create(
  args: {
    board_name: "Sprint Planning",
    board_kind: :public,
    folder_id: folder_id
  }
)
```

## Customize Response Fields

Choose which fields to return:

```ruby
response = client.board.create(
  args: {
    board_name: "Custom Fields Board",
    board_kind: :public
  },
  select: [
    "id",
    "name",
    "description",
    "state",
    "board_folder_id",
    "workspace_id"
  ]
)

if response.success?
  board = response.body.dig("data", "create_board")

  puts "Board Details:"
  puts "  ID: #{board['id']}"
  puts "  Name: #{board['name']}"
  puts "  State: #{board['state']}"
  puts "  Workspace: #{board['workspace_id']}"
  puts "  Folder: #{board['board_folder_id'] || 'None'}"
end
```

## Get Board URL

Retrieve the board's URL after creation:

```ruby
response = client.board.create(
  args: {
    board_name: "New Board",
    board_kind: :public
  },
  select: ["id", "name", "url"]
)

if response.success?
  board = response.body.dig("data", "create_board")
  puts "✓ Board created!"
  puts "  View at: #{board['url']}"
end
```

## Create with Columns

Query the created board to see default columns:

```ruby
response = client.board.create(
  args: {
    board_name: "Board with Columns",
    board_kind: :public
  },
  select: [
    "id",
    "name",
    {
      columns: ["id", "title", "type"]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "create_board")

  puts "Board: #{board['name']}"
  puts "Default columns:"

  board["columns"].each do |column|
    puts "  • #{column['title']} (#{column['type']})"
  end
end
```

**Example output:**
```
Board: Board with Columns
Default columns:
  • Name (name)
  • Person (people)
  • Status (color)
  • Date (date)
```

## Error Handling

Handle common creation errors:

```ruby
def create_board_safe(client, name, kind)
  response = client.board.create(
    args: {
      board_name: name,
      board_kind: kind
    }
  )

  if response.success?
    board = response.body.dig("data", "create_board")
    puts "✓ Created: #{board['name']} (ID: #{board['id']})"
    board['id']
  else
    puts "✗ Failed to create board"
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
board_id = create_board_safe(client, "Safe Board", :public)
```

## Complete Example

Create a fully configured board:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# Create board with all options
response = client.board.create(
  args: {
    board_name: "Q1 2024 Projects",
    board_kind: :public,
    description: "All projects planned for Q1 2024",
    workspace_id: 9876543210,  # Optional: your workspace ID
    folder_id: 5555555555       # Optional: your folder ID
  },
  select: [
    "id",
    "name",
    "description",
    "url",
    "state",
    {
      columns: ["id", "title", "type"]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "create_board")

  puts "\n✓ Board Created Successfully\n"
  puts "#{'=' * 50}"
  puts "Name: #{board['name']}"
  puts "ID: #{board['id']}"
  puts "URL: #{board['url']}"
  puts "Description: #{board['description']}"
  puts "\nDefault Columns:"

  board["columns"].each do |column|
    puts "  • #{column['title']} (type: #{column['type']})"
  end

  puts "#{'=' * 50}"
else
  puts "\n✗ Failed to create board"
  puts "Status code: #{response.status}"

  if response.body["error_message"]
    puts "Error: #{response.body['error_message']}"
  end
end
```

## Validate Board Name

Check for valid board names before creating:

```ruby
def valid_board_name?(name)
  return false if name.nil? || name.empty?
  return false if name.length > 255

  true
end

board_name = "My New Board"

if valid_board_name?(board_name)
  response = client.board.create(
    args: {
      board_name: board_name,
      board_kind: :public
    }
  )
else
  puts "Invalid board name"
end
```

## Next Steps

- [Query boards](/guides/boards/query)
- [Update board settings](/guides/boards/update)
- [Add items to boards](/guides/items/create)
- [Duplicate boards](/guides/boards/duplicate)
