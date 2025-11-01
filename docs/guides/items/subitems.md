# Manage Subitems

Work with subitems (child items) to break down tasks into smaller, manageable pieces.

## What are Subitems?

Subitems are child items that live under a parent item. They help you:
- Break down large tasks into smaller steps
- Track progress at a more granular level
- Organize work hierarchically

## Create a Subitem

Add a subitem to an existing item:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.subitem.create(
  args: {
    parent_item_id: 987654321,  # The parent item ID
    item_name: "Subitem Task"
  }
)

if response.success?
  subitem = response.body.dig("data", "create_subitem")
  puts "✓ Created subitem: #{subitem['name']}"
  puts "  ID: #{subitem['id']}"
  puts "  Created: #{subitem['created_at']}"
else
  puts "✗ Failed to create subitem"
end
```

**Output:**
```
✓ Created subitem: Subitem Task
  ID: 7092811738
  Created: 2024-07-25T04:00:04Z
```

## Create Multiple Subitems

Break down a task into multiple steps:

```ruby
parent_item_id = 987654321
subtasks = [
  "Design mockups",
  "Get feedback",
  "Revise design",
  "Final approval"
]

created_subitems = []

subtasks.each do |task_name|
  response = client.subitem.create(
    args: {
      parent_item_id: parent_item_id,
      item_name: task_name
    }
  )

  if response.success?
    subitem = response.body.dig("data", "create_subitem")
    created_subitems << subitem
    puts "✓ Created: #{subitem['name']}"
  end

  sleep(0.3)  # Rate limiting
end

puts "\nCreated #{created_subitems.length} subitems"
```

**Output:**
```
✓ Created: Design mockups
✓ Created: Get feedback
✓ Created: Revise design
✓ Created: Final approval

Created 4 subitems
```

## Create Subitem with Column Values

Set column values when creating a subitem:

```ruby
# Note: Replace column IDs with your board's actual column IDs
response = client.subitem.create(
  args: {
    parent_item_id: 987654321,
    item_name: "Design Phase",
    column_values: {
      status: {  # ⚠️ Your status column ID
        label: "Working on it"
      },
      date4: {  # ⚠️ Your date column ID
        date: "2024-12-15"
      }
    }
  }
)

if response.success?
  subitem = response.body.dig("data", "create_subitem")
  puts "✓ Subitem created with column values"
end
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Finding Column IDs</span>
Subitems live on a subitems board. Query that board's columns to get the correct column IDs. See [Create Items guide](/guides/items/create#finding-column-ids) for details.
:::

## Query Subitems

Retrieve subitems for a parent item:

```ruby
response = client.subitem.query(
  args: { ids: [987654321] }  # Parent item ID
)

if response.success?
  items = response.body.dig("data", "items")
  subitems = items.first&.dig("subitems") || []

  puts "Found #{subitems.length} subitems:"
  subitems.each do |subitem|
    puts "  • #{subitem['name']} (ID: #{subitem['id']})"
  end
end
```

## Query with Custom Fields

Get additional details about subitems:

```ruby
response = client.subitem.query(
  args: { ids: [987654321] },
  select: [
    "id",
    "name",
    "created_at",
    "state",
    {
      column_values: ["id", "text", "type"]
    }
  ]
)

if response.success?
  items = response.body.dig("data", "items")
  subitems = items.first&.dig("subitems") || []

  subitems.each do |subitem|
    puts "\n#{subitem['name']}"
    puts "  ID: #{subitem['id']}"
    puts "  State: #{subitem['state']}"
    puts "  Created: #{subitem['created_at']}"

    if subitem["column_values"]
      puts "  Column Values:"
      subitem["column_values"].each do |col|
        next if col["text"].nil? || col["text"].empty?
        puts "    • #{col['id']}: #{col['text']}"
      end
    end
  end
end
```

## Query Multiple Parent Items

Get subitems for multiple items at once:

```ruby
parent_item_ids = [987654321, 987654322, 987654323]

response = client.subitem.query(
  args: { ids: parent_item_ids },
  select: ["id", "name", "created_at"]
)

if response.success?
  items = response.body.dig("data", "items")

  items.each do |item|
    subitems = item["subitems"] || []
    puts "\nParent: Item #{item['id']}"
    puts "  Subitems: #{subitems.length}"

    subitems.each do |subitem|
      puts "    • #{subitem['name']}"
    end
  end
end
```

## Update Subitem Values

Subitems are regular items, so use the item/column update methods:

```ruby
# Update a subitem's column value
subitem_id = 7092811738

response = client.column.change_value(
  args: {
    board_id: 1234567890,  # The subitems board ID
    item_id: subitem_id,
    column_id: "status",  # ⚠️ Your status column ID
    value: JSON.generate({ label: "Done" })
  }
)

if response.success?
  puts "✓ Subitem updated"
end
```

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Subitems Board ID</span>
To update subitem values, you need the **subitems board ID**, not the parent board ID. Query the parent item to find the subitems board ID.
:::

## Get Subitems Board ID

Find the board ID for subitems:

```ruby
# Query the parent item to get subitems board reference
response = client.item.query(
  args: { ids: [987654321] },
  select: [
    "id",
    "name",
    {
      board: ["id", "name"]
    }
  ]
)

if response.success?
  item = response.body.dig("data", "items", 0)
  board = item.dig("board")

  puts "Item: #{item['name']}"
  puts "Board: #{board['name']} (ID: #{board['id']})"
  puts "\nSubitems will be on a related subitems board"
end
```

## Delete Subitems

Subitems are items, so use the item delete method:

```ruby
subitem_id = 7092811738

response = client.item.delete(subitem_id)

if response.success?
  puts "✓ Subitem deleted"
end
```

## Complete Example

Create and manage a project with subitems:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# First, create a parent item
parent_response = client.item.create(
  args: {
    board_id: 1234567890,
    item_name: "Website Redesign Project"
  }
)

parent_item = parent_response.body.dig("data", "create_item")
puts "✓ Created parent item: #{parent_item['name']}"

# Define project phases as subitems
phases = [
  "Research & Planning",
  "Design Mockups",
  "Development",
  "Testing & QA",
  "Launch"
]

# Create subitems for each phase
puts "\nCreating project phases..."
phases.each do |phase_name|
  response = client.subitem.create(
    args: {
      parent_item_id: parent_item["id"],
      item_name: phase_name
    },
    select: ["id", "name", "created_at"]
  )

  if response.success?
    subitem = response.body.dig("data", "create_subitem")
    puts "  ✓ #{subitem['name']}"
  end

  sleep(0.3)
end

# Query all subitems
puts "\nQuerying created subitems..."
query_response = client.subitem.query(
  args: { ids: [parent_item["id"]] },
  select: ["id", "name"]
)

if query_response.success?
  items = query_response.body.dig("data", "items")
  subitems = items.first&.dig("subitems") || []

  puts "\n" + "=" * 50
  puts "Project: #{parent_item['name']}"
  puts "Phases: #{subitems.length}"
  puts "\nSubitems:"
  subitems.each_with_index do |subitem, index|
    puts "  #{index + 1}. #{subitem['name']} (ID: #{subitem['id']})"
  end
  puts "=" * 50
end
```

**Output:**
```
✓ Created parent item: Website Redesign Project

Creating project phases...
  ✓ Research & Planning
  ✓ Design Mockups
  ✓ Development
  ✓ Testing & QA
  ✓ Launch

Querying created subitems...

==================================================
Project: Website Redesign Project
Phases: 5

Subitems:
  1. Research & Planning (ID: 7092811740)
  2. Design Mockups (ID: 7092811741)
  3. Development (ID: 7092811742)
  4. Testing & QA (ID: 7092811743)
  5. Launch (ID: 7092811744)
==================================================
```

## Count Subitems

Count how many subitems an item has:

```ruby
response = client.subitem.query(
  args: { ids: [987654321] },
  select: ["id", "name"]
)

if response.success?
  items = response.body.dig("data", "items")
  subitems = items.first&.dig("subitems") || []

  puts "This item has #{subitems.length} subitems"
end
```

## Filter Parent Items by Subitem Count

Find items with or without subitems:

```ruby
# Query multiple items
response = client.item.query(
  args: { ids: [987654321, 987654322, 987654323] },
  select: [
    "id",
    "name",
    {
      subitems: ["id"]
    }
  ]
)

if response.success?
  items = response.body.dig("data", "items")

  items_with_subitems = items.select do |item|
    subitems = item["subitems"] || []
    subitems.length > 0
  end

  puts "Items with subitems: #{items_with_subitems.length}"
  items_with_subitems.each do |item|
    subitem_count = item["subitems"].length
    puts "  • #{item['name']} (#{subitem_count} subitems)"
  end
end
```

## Error Handling

Handle common subitem errors:

```ruby
def create_subitem_safe(client, parent_item_id, subitem_name)
  response = client.subitem.create(
    args: {
      parent_item_id: parent_item_id,
      item_name: subitem_name
    }
  )

  if response.success?
    subitem = response.body.dig("data", "create_subitem")
    puts "✓ Created: #{subitem['name']}"
    subitem["id"]
  else
    puts "✗ Failed to create subitem"
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
subitem_id = create_subitem_safe(client, 987654321, "New Subitem")
```

## Best Practices

### Use Subitems For

- Breaking down large tasks into steps
- Tracking sub-components of a feature
- Managing checklist items
- Organizing hierarchical work

### Avoid Subitems For

- Deep nesting (subitems can't have their own subitems)
- Unrelated tasks (use groups or separate items instead)
- Cross-board relationships (use connect boards column)

## Next Steps

- [Create items](/guides/items/create)
- [Query items](/guides/items/query)
- [Update column values](/guides/items/update)
- [Work with groups](/guides/boards/query#query-with-groups)
