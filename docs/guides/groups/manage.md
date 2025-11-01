# Manage Groups

Learn how to create, update, organize, and delete groups on your monday.com boards.

## What are Groups?

Groups are sections within boards that organize related items together. They act like categories or folders, helping you structure your board's content logically. For example, a project board might have groups like "To Do", "In Progress", and "Done".

## Query Groups

Retrieve groups from one or more boards:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.group.query(
  args: { ids: [123] },
  select: ["id", "title", "color"]
)

if response.success?
  boards = response.body.dig("data", "boards")
  boards.each do |board|
    puts "Board groups:"
    board["groups"].each do |group|
      puts "  • #{group['title']} (#{group['id']})"
    end
  end
end
```

**Output:**
```
Board groups:
  • To Do (group_mkx1yn2n)
  • In Progress (group_abc123)
  • Done (group_xyz789)
```

### Query Multiple Boards

Get groups from several boards at once:

```ruby
response = client.group.query(
  args: { ids: [123, 456, 789] },
  select: ["id", "title", "position"]
)

boards = response.body.dig("data", "boards")
boards.each do |board|
  board["groups"].each do |group|
    puts "Board #{board['id']}: #{group['title']} (position: #{group['position']})"
  end
end
```

### Include Group Details

Retrieve additional group information:

```ruby
response = client.group.query(
  args: { ids: [123] },
  select: [
    "id",
    "title",
    "color",
    "position",
    "archived",
    {
      items: ["id", "name"]  # Get items in each group
    }
  ]
)

boards = response.body.dig("data", "boards")
boards.each do |board|
  board["groups"].each do |group|
    puts "\nGroup: #{group['title']}"
    puts "  Color: #{group['color']}"
    puts "  Position: #{group['position']}"
    puts "  Archived: #{group['archived']}"
    puts "  Items: #{group['items'].length}"
  end
end
```

## Create Groups

Add new groups to organize your board:

### Basic Group Creation

```ruby
response = client.group.create(
  args: {
    board_id: 123,
    group_name: "Returned Orders"
  }
)

if response.success?
  group = response.body.dig("data", "create_group")
  puts "✓ Created group: #{group['title']}"
  puts "  ID: #{group['id']}"
end
```

**Output:**
```
✓ Created group: Returned Orders
  ID: group_mkx1yn2n
```

### Create at Specific Position

Add group at the top of the board:

```ruby
response = client.group.create(
  args: {
    board_id: 123,
    group_name: "Urgent Items",
    position: "0"  # Position at top
  }
)
```

Add group after another group:

```ruby
response = client.group.create(
  args: {
    board_id: 123,
    group_name: "Review",
    position: "group_mkx1yn2n",  # Insert after this group
    position_relative_method: :after_at
  }
)
```

### Create Multiple Groups

Batch create several groups:

```ruby
group_names = ["Planning", "Design", "Development", "Testing", "Deployment"]

group_names.each do |name|
  response = client.group.create(
    args: {
      board_id: 123,
      group_name: name
    }
  )

  if response.success?
    group = response.body.dig("data", "create_group")
    puts "✓ Created: #{group['title']}"
  else
    puts "✗ Failed to create: #{name}"
  end
end
```

**Output:**
```
✓ Created: Planning
✓ Created: Design
✓ Created: Development
✓ Created: Testing
✓ Created: Deployment
```

## Update Groups

Modify group properties after creation:

### Rename Group

```ruby
response = client.group.update(
  args: {
    board_id: 123,
    group_id: "group_mkx1yn2n",
    group_attribute: :title,
    new_value: "Completed Returns"
  }
)

if response.success?
  puts "✓ Group renamed successfully"
end
```

### Change Group Color

```ruby
response = client.group.update(
  args: {
    board_id: 123,
    group_id: "group_mkx1yn2n",
    group_attribute: :color,
    new_value: "#00c875"  # Green color
  }
)
```

**Common colors:**
- `#e2445c` - Red
- `#fdab3d` - Orange
- `#ffcb00` - Yellow
- `#00c875` - Green
- `#0086c0` - Blue
- `#a25ddc` - Purple

### Reposition Group

Move group to different position:

```ruby
response = client.group.update(
  args: {
    board_id: 123,
    group_id: "group_mkx1yn2n",
    group_attribute: :position,
    new_value: "0"  # Move to top
  }
)
```

## Duplicate Groups

Copy a group with all its items:

### Basic Duplication

```ruby
response = client.group.duplicate(
  args: {
    board_id: 123,
    group_id: "group_mkx1yn2n"
  }
)

if response.success?
  duplicated = response.body.dig("data", "duplicate_group")
  puts "✓ Duplicated group: #{duplicated['title']}"
  puts "  New ID: #{duplicated['id']}"
end
```

### Duplicate with Custom Name

```ruby
response = client.group.duplicate(
  args: {
    board_id: 123,
    group_id: "group_mkx1yn2n",
    group_title: "Archive - Q4 2024"
  }
)
```

### Duplicate to Top

Add duplicated group at the top of the board:

```ruby
response = client.group.duplicate(
  args: {
    board_id: 123,
    group_id: "group_mkx1yn2n",
    group_title: "Copy of Returns",
    add_to_top: true
  }
)
```

## Archive Groups

Archive groups to hide them without deleting:

```ruby
response = client.group.archive(
  args: {
    board_id: 123,
    group_id: "group_mkx1yn2n"
  }
)

if response.success?
  puts "✓ Group archived successfully"
end
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Archive vs Delete</span>
Archiving preserves the group and its items for future reference. Deleted groups and their items are permanently removed. Always archive unless you're certain the data isn't needed.
:::

### Archive Multiple Groups

Batch archive completed groups:

```ruby
completed_group_ids = ["group_abc123", "group_xyz789", "group_mkx1yn2n"]

completed_group_ids.each do |group_id|
  response = client.group.archive(
    args: {
      board_id: 123,
      group_id: group_id
    }
  )

  if response.success?
    puts "✓ Archived group: #{group_id}"
  end
end
```

## Delete Groups

Permanently remove groups and their items:

```ruby
response = client.group.delete(
  args: {
    board_id: 123,
    group_id: "group_mkx1yn2n"
  }
)

if response.success?
  deleted = response.body.dig("data", "delete_group")
  puts "✓ Deleted group: #{deleted['id']}"
end
```

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Permanent Deletion</span>
Deleting a group removes all items within it. This cannot be undone. Consider archiving instead to preserve historical data.
:::

### Safe Delete with Confirmation

```ruby
def delete_group_safe(client, board_id, group_id, group_name)
  puts "⚠️  WARNING: You are about to delete '#{group_name}'"
  puts "   All items in this group will be permanently removed."
  print "   Type 'DELETE' to confirm: "

  confirmation = gets.chomp

  if confirmation == "DELETE"
    response = client.group.delete(
      args: {
        board_id: board_id,
        group_id: group_id
      }
    )

    if response.success?
      puts "✓ Group deleted"
    else
      puts "✗ Failed to delete group"
    end
  else
    puts "Deletion cancelled"
  end
end

# Usage
delete_group_safe(client, 123, "group_mkx1yn2n", "Old Projects")
```

## Error Handling

Handle common errors when managing groups:

```ruby
def create_group_safe(client, board_id, group_name)
  response = client.group.create(
    args: {
      board_id: board_id,
      group_name: group_name
    }
  )

  if response.success?
    group = response.body.dig("data", "create_group")
    puts "✓ Created: #{group['title']} (#{group['id']})"
    group['id']
  else
    puts "✗ Failed to create group"
    nil
  end
rescue Monday::ResourceNotFoundError
  puts "✗ Board not found: #{board_id}"
  nil
rescue Monday::AuthorizationError
  puts "✗ No permission to create groups on this board"
  nil
rescue Monday::Error => e
  puts "✗ Error: #{e.message}"
  nil
end

# Usage
group_id = create_group_safe(client, 123, "New Group")
```

## Complete Example

Full workflow for managing groups:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new
board_id = 123

# 1. Query existing groups
puts "=== Current Groups ==="
response = client.group.query(
  args: { ids: [board_id] },
  select: ["id", "title", "color"]
)

groups = response.body.dig("data", "boards", 0, "groups")
groups.each do |group|
  puts "• #{group['title']} (#{group['id']})"
end

# 2. Create new group
puts "\n=== Creating New Group ==="
response = client.group.create(
  args: {
    board_id: board_id,
    group_name: "Q1 2024 Projects"
  }
)

new_group = response.body.dig("data", "create_group")
puts "✓ Created: #{new_group['title']} (#{new_group['id']})"

# 3. Update group
puts "\n=== Updating Group ==="
response = client.group.update(
  args: {
    board_id: board_id,
    group_id: new_group['id'],
    group_attribute: :color,
    new_value: "#00c875"
  }
)
puts "✓ Updated group color"

# 4. Duplicate group
puts "\n=== Duplicating Group ==="
response = client.group.duplicate(
  args: {
    board_id: board_id,
    group_id: new_group['id'],
    group_title: "Q2 2024 Projects"
  }
)

duplicated = response.body.dig("data", "duplicate_group")
puts "✓ Duplicated: #{duplicated['title']} (#{duplicated['id']})"

# 5. Archive original group
puts "\n=== Archiving Group ==="
response = client.group.archive(
  args: {
    board_id: board_id,
    group_id: new_group['id']
  }
)
puts "✓ Archived group: #{new_group['id']}"

puts "\n=== Complete ==="
```

## Next Steps

- [Work with items in groups](/guides/groups/items)
- [Create items in groups](/guides/items/create)
- [Query group items](/guides/items/query)
- [Manage boards](/guides/boards/query)
