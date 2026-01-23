# Duplicate Boards

Create copies of existing boards with different duplication options.

## Basic Duplication

Duplicate a board's structure without items:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

board_id = 1234567890

response = client.board.duplicate(
  args: {
    board_id: board_id,
    duplicate_type: :duplicate_board_with_structure
  }
)

if response.success?
  duplicated = response.body.dig("data", "duplicate_board", "board")
  puts "✓ Duplicated board"
  puts "  New ID: #{duplicated['id']}"
  puts "  Name: #{duplicated['name']}"
else
  puts "✗ Duplication failed"
end
```

## Duplication Types

### Structure Only

Copy columns, groups, and settings without items:

```ruby
response = client.board.duplicate(
  args: {
    board_id: 1234567890,
    duplicate_type: :duplicate_board_with_structure
  }
)
```

Perfect for creating new projects with the same structure.

### Structure and Items

Copy everything including all items (but not updates):

```ruby
response = client.board.duplicate(
  args: {
    board_id: 1234567890,
    duplicate_type: :duplicate_board_with_pulses
  }
)

if response.success?
  duplicated = response.body.dig("data", "duplicate_board", "board")
  puts "✓ Duplicated board with items"
  puts "  New ID: #{duplicated['id']}"
end
```

:::tip Pulses = Items
In monday.com's API, "pulses" is the legacy term for "items". Both refer to the same thing.
:::

### Structure, Items, and Updates

Full duplication including all updates and comments:

```ruby
response = client.board.duplicate(
  args: {
    board_id: 1234567890,
    duplicate_type: :duplicate_board_with_pulses_and_updates
  }
)

if response.success?
  duplicated = response.body.dig("data", "duplicate_board", "board")
  puts "✓ Full duplication complete"
  puts "  Includes: structure, items, updates"
end
```

## Custom Board Name

Specify a name for the duplicated board:

```ruby
response = client.board.duplicate(
  args: {
    board_id: 1234567890,
    duplicate_type: :duplicate_board_with_structure,
    board_name: "Q2 2024 Sprint Planning"
  }
)

if response.success?
  duplicated = response.body.dig("data", "duplicate_board", "board")
  puts "✓ Created: #{duplicated['name']}"
end
```

If not specified, monday.com appends "copy of" to the original name.

## Duplicate to Workspace

Place the duplicate in a specific workspace:

```ruby
workspace_id = 9876543210

response = client.board.duplicate(
  args: {
    board_id: 1234567890,
    duplicate_type: :duplicate_board_with_structure,
    workspace_id: workspace_id
  }
)

if response.success?
  duplicated = response.body.dig("data", "duplicate_board", "board")
  puts "✓ Duplicated to workspace: #{workspace_id}"
  puts "  Board ID: #{duplicated['id']}"
end
```

## Duplicate to Folder

Organize the duplicate in a folder:

```ruby
folder_id = 5555555555

response = client.board.duplicate(
  args: {
    board_id: 1234567890,
    duplicate_type: :duplicate_board_with_structure,
    folder_id: folder_id
  }
)

if response.success?
  duplicated = response.body.dig("data", "duplicate_board", "board")
  puts "✓ Duplicated to folder: #{folder_id}"
end
```

## Custom Response Fields

Request specific fields from the duplicated board:

```ruby
response = client.board.duplicate(
  args: {
    board_id: 1234567890,
    duplicate_type: :duplicate_board_with_structure
  },
  select: [
    "id",
    "name",
    "description",
    "url",
    {
      columns: ["id", "title", "type"],
      groups: ["id", "title"]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "duplicate_board", "board")

  puts "Duplicated Board:"
  puts "  ID: #{board['id']}"
  puts "  Name: #{board['name']}"
  puts "  URL: #{board['url']}"
  puts "  Columns: #{board['columns'].length}"
  puts "  Groups: #{board['groups'].length}"
end
```

## Verify Duplication

Confirm the duplicate was created successfully:

```ruby
def duplicate_and_verify(client, board_id, duplicate_type)
  # Duplicate
  dup_response = client.board.duplicate(
    args: {
      board_id: board_id,
      duplicate_type: duplicate_type
    },
    select: ["id", "name", { columns: ["id"] }]
  )

  unless dup_response.success?
    puts "✗ Duplication failed"
    return nil
  end

  duplicated = dup_response.body.dig("data", "duplicate_board", "board")

  # Verify by querying
  verify_response = client.board.query(
    args: { ids: [duplicated['id']] },
    select: ["id", "name", { columns: ["id"] }]
  )

  if verify_response.success?
    board = verify_response.body.dig("data", "boards", 0)

    puts "✓ Duplication verified"
    puts "  Name: #{board['name']}"
    puts "  Columns: #{board['columns'].length}"

    duplicated['id']
  else
    puts "⚠ Duplication succeeded but verification failed"
    duplicated['id']
  end
end

# Usage
new_board_id = duplicate_and_verify(
  client,
  1234567890,
  :duplicate_board_with_structure
)
```

## Duplicate with Options

Full duplication with all options:

```ruby
response = client.board.duplicate(
  args: {
    board_id: 1234567890,
    duplicate_type: :duplicate_board_with_structure,
    board_name: "Sprint 15 - Customer Portal",
    workspace_id: 9876543210,
    folder_id: 5555555555,
    keep_subscribers: true
  },
  select: [
    "id",
    "name",
    "url",
    { workspace: ["id", "name"] }
  ]
)

if response.success?
  board = response.body.dig("data", "duplicate_board", "board")
  workspace = board.dig("workspace")

  puts "✓ Board duplicated successfully"
  puts "  Name: #{board['name']}"
  puts "  ID: #{board['id']}"
  puts "  Workspace: #{workspace&.dig('name')}"
  puts "  URL: #{board['url']}"
end
```

## Error Handling

Handle duplication errors:

```ruby
def safe_duplicate(client, board_id, duplicate_type, board_name: nil)
  response = client.board.duplicate(
    args: {
      board_id: board_id,
      duplicate_type: duplicate_type,
      board_name: board_name
    }.compact
  )

  if response.success?
    board = response.body.dig("data", "duplicate_board", "board")
    puts "✓ Duplicated: #{board['name']} (ID: #{board['id']})"
    board['id']
  else
    puts "✗ Duplication failed"
    puts "  Status: #{response.status}"

    if response.body["error_message"]
      puts "  Error: #{response.body['error_message']}"
    end

    nil
  end
rescue Monday::AuthorizationError
  puts "✗ Board not found or no permission"
  nil
rescue Monday::Error => e
  if e.message.include?("invalid_type")
    puts "✗ Invalid duplicate_type"
  else
    puts "✗ API error: #{e.message}"
  end
  nil
end

# Usage
safe_duplicate(
  client,
  1234567890,
  :duplicate_board_with_structure,
  board_name: "New Sprint Board"
)
```

## Bulk Duplication

Duplicate multiple boards:

```ruby
def bulk_duplicate(client, board_ids, duplicate_type)
  results = { success: [], failed: [] }

  board_ids.each do |board_id|
    response = client.board.duplicate(
      args: {
        board_id: board_id,
        duplicate_type: duplicate_type
      }
    )

    if response.success?
      board = response.body.dig("data", "duplicate_board", "board")
      results[:success] << { original: board_id, duplicate: board['id'] }
      puts "✓ Duplicated: #{board_id} → #{board['id']}"
    else
      results[:failed] << board_id
      puts "✗ Failed: #{board_id}"
    end
  end

  puts "\nResults:"
  puts "  Success: #{results[:success].length}"
  puts "  Failed: #{results[:failed].length}"

  results
end

# Usage
boards_to_duplicate = [1234567890, 2345678901, 3456789012]

results = bulk_duplicate(
  client,
  boards_to_duplicate,
  :duplicate_board_with_structure
)
```

## Template System

Create a template duplication system:

```ruby
TEMPLATES = {
  sprint: {
    board_id: 1234567890,
    duplicate_type: :duplicate_board_with_structure,
    prefix: "Sprint"
  },
  project: {
    board_id: 2345678901,
    duplicate_type: :duplicate_board_with_structure,
    prefix: "Project"
  }
}.freeze

def create_from_template(client, template_name, name)
  template = TEMPLATES[template_name]

  unless template
    puts "✗ Template '#{template_name}' not found"
    return nil
  end

  board_name = "#{template[:prefix]} - #{name}"

  response = client.board.duplicate(
    args: {
      board_id: template[:board_id],
      duplicate_type: template[:duplicate_type],
      board_name: board_name
    }
  )

  if response.success?
    board = response.body.dig("data", "duplicate_board", "board")
    puts "✓ Created from template: #{board['name']}"
    board['id']
  else
    puts "✗ Template duplication failed"
    nil
  end
end

# Usage
create_from_template(client, :sprint, "Customer Portal Feature")
# Creates: "Sprint - Customer Portal Feature"
```

## Duplication Types Comparison

| Type | Structure | Items | Updates | Use Case |
|------|-----------|-------|---------|----------|
| `duplicate_board_with_structure` | ✓ | ✗ | ✗ | New projects with same structure |
| `duplicate_board_with_pulses` | ✓ | ✓ | ✗ | Backup or fork with data |
| `duplicate_board_with_pulses_and_updates` | ✓ | ✓ | ✓ | Complete archive or clone |

## Complete Example

Full-featured board duplication:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# Original board
original_board_id = 1234567890

# Step 1: Get original board info
puts "\n📋 Fetching original board..."
query_response = client.board.query(
  args: { ids: [original_board_id] },
  select: [
    "id",
    "name",
    "description",
    { items: ["id"], columns: ["id"] }
  ]
)

unless query_response.success?
  puts "❌ Original board not found"
  exit
end

original = query_response.body.dig("data", "boards", 0)

puts "\nOriginal Board:"
puts "  Name: #{original['name']}"
puts "  Items: #{original['items'].length}"
puts "  Columns: #{original['columns'].length}"

# Step 2: Duplicate
puts "\n🔄 Duplicating board..."

dup_response = client.board.duplicate(
  args: {
    board_id: original_board_id,
    duplicate_type: :duplicate_board_with_structure,
    board_name: "#{original['name']} - Copy"
  },
  select: [
    "id",
    "name",
    "url",
    { columns: ["id", "title"], groups: ["id", "title"] }
  ]
)

unless dup_response.success?
  puts "❌ Duplication failed"
  exit
end

duplicated = dup_response.body.dig("data", "duplicate_board", "board")

# Step 3: Display results
puts "\n✓ Duplication Complete!"
puts "=" * 50
puts "New Board:"
puts "  Name: #{duplicated['name']}"
puts "  ID: #{duplicated['id']}"
puts "  URL: #{duplicated['url']}"
puts "  Columns: #{duplicated['columns'].length}"
puts "  Groups: #{duplicated['groups'].length}"
puts "=" * 50
```
