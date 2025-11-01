# Create Items

Add items (tasks, rows) to boards programmatically.

## Finding Column IDs

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Column IDs are Board-Specific</span>
**Before setting column values, you must find your board's actual column IDs.** Column IDs like `status`, `text`, or `date` in these examples are placeholders - replace them with your board's real column IDs.
:::

Query your board to get column IDs:

```ruby
response = client.board.query(
  args: { ids: [1234567890] },  # Replace with your board ID
  select: [
    "id",
    "name",
    {
      columns: ["id", "title", "type"]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "boards", 0)

  puts "Columns for board '#{board['name']}':"
  board["columns"].each do |column|
    puts "  • #{column['title']}: '#{column['id']}' (#{column['type']})"
  end
end
```

**Example output:**
```
Columns for board 'Marketing Campaigns':
  • Name: 'name' (name)
  • Status: 'status' (color)
  • Owner: 'people' (people)
  • Due Date: 'date4' (date)
  • Priority: 'status_1' (color)
  • Text: 'text' (text)
```

Use these exact column IDs (e.g., `date4`, `status_1`) in your code, not the column titles.

## Basic Item Creation

Create an item with just a name:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.item.create(
  args: {
    board_id: 1234567890,
    item_name: "New Task"
  }
)

if response.success?
  item = response.body.dig("data", "create_item")
  puts "✓ Created item: #{item['name']}"
  puts "  ID: #{item['id']}"
else
  puts "✗ Failed to create item"
end
```

**Output:**
```
✓ Created item: New Task
  ID: 987654321
```

## Create with Column Values

Set column values when creating an item:

### Status Column

```ruby
# Replace 'status' with your actual column ID from the query above
response = client.item.create(
  args: {
    board_id: 1234567890,
    item_name: "Task with Status",
    column_values: {
      status: {  # ⚠️ Replace 'status' with your board's status column ID
        label: "Done"
      }
    }
  }
)

if response.success?
  item = response.body.dig("data", "create_item")
  puts "Created: #{item['name']}"
end
```

### Multiple Columns

Set multiple column values at once:

```ruby
# ⚠️ Replace column IDs with your board's actual column IDs
response = client.item.create(
  args: {
    board_id: 1234567890,
    item_name: "Complete Task Setup",
    column_values: {
      status: {  # Your status column ID
        label: "Working on it"
      },
      text: "High priority task",  # Your text column ID
      date4: {  # Your date column ID (e.g., 'date4', 'date', etc.)
        date: "2024-12-31",
        time: "14:00:00"
      },
      people: {  # Your people column ID
        personsAndTeams: [
          { id: 12345678, kind: "person" }  # Replace with actual user ID
        ]
      }
    }
  }
)
```

## Create in Specific Group

Add item to a particular group (section) on the board:

```ruby
# First, get the group ID
board_response = client.board.query(
  args: { ids: [1234567890] },
  select: [
    "id",
    {
      groups: ["id", "title"]
    }
  ]
)

board = board_response.body.dig("data", "boards", 0)
group_id = board.dig("groups", 0, "id")

# Create item in that group
response = client.item.create(
  args: {
    board_id: 1234567890,
    group_id: group_id,
    item_name: "Task in Specific Group"
  }
)

if response.success?
  item = response.body.dig("data", "create_item")
  puts "✓ Item created in group #{group_id}"
end
```

## Auto-Create Status Labels

Automatically create new status labels if they don't exist:

```ruby
response = client.item.create(
  args: {
    board_id: 1234567890,
    item_name: "Task with New Label",
    column_values: {
      status__1: {
        label: "Custom Status"
      }
    },
    create_labels_if_missing: true
  }
)

if response.success?
  puts "✓ Item created with custom status label"
end
```

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Status Labels</span>
Without `create_labels_if_missing: true`, attempting to use non-existent status labels will cause an error.
:::

## Customize Response Fields

Choose which fields to return:

```ruby
response = client.item.create(
  args: {
    board_id: 1234567890,
    item_name: "Detailed Item"
  },
  select: [
    "id",
    "name",
    "created_at",
    "state",
    "board { id name }",
    "group { id title }"
  ]
)

if response.success?
  item = response.body.dig("data", "create_item")

  puts "Item Details:"
  puts "  ID: #{item['id']}"
  puts "  Name: #{item['name']}"
  puts "  Created: #{item['created_at']}"
  puts "  Board: #{item.dig('board', 'name')}"
  puts "  Group: #{item.dig('group', 'title')}"
end
```

## Bulk Create Items

Create multiple items efficiently:

```ruby
def create_items_bulk(client, board_id, item_names)
  created_items = []

  item_names.each do |name|
    response = client.item.create(
      args: {
        board_id: board_id,
        item_name: name
      }
    )

    if response.success?
      item = response.body.dig("data", "create_item")
      created_items << item
      puts "✓ Created: #{item['name']}"
    else
      puts "✗ Failed to create: #{name}"
    end

    # Rate limiting: pause between requests
    sleep(0.5)
  end

  created_items
end

# Usage
tasks = [
  "Design mockups",
  "Implement feature",
  "Write tests",
  "Deploy to staging",
  "QA review"
]

items = create_items_bulk(client, 1234567890, tasks)
puts "\nCreated #{items.length} items"
```

## Create with JSON Column Values

For complex column types, use JSON strings:

```ruby
require "json"

column_values = {
  status__1: { label: "Done" },
  date: { date: "2024-12-31" }
}

response = client.item.create(
  args: {
    board_id: 1234567890,
    item_name: "Task with JSON Values",
    column_values: JSON.generate(column_values)
  }
)
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Hash vs JSON</span>
The gem automatically converts Hash column values to JSON. You can pass either format.
:::

## Error Handling

Handle common creation errors:

```ruby
def create_item_safe(client, board_id, name, columns = {})
  response = client.item.create(
    args: {
      board_id: board_id,
      item_name: name,
      column_values: columns
    }
  )

  if response.success?
    item = response.body.dig("data", "create_item")
    puts "✓ Created: #{item['name']} (ID: #{item['id']})"
    item['id']
  else
    puts "✗ Failed to create item: #{name}"
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
rescue Monday::InvalidRequestError => e
  puts "✗ Invalid request: #{e.message}"
  nil
rescue Monday::Error => e
  puts "✗ API error: #{e.message}"
  nil
end

# Usage
item_id = create_item_safe(
  client,
  1234567890,
  "Safe Task",
  { status__1: { label: "Done" } }
)
```

## Validate Item Names

Check for valid item names before creating:

```ruby
def valid_item_name?(name)
  return false if name.nil? || name.empty?
  return false if name.length > 255

  true
end

item_name = "My New Task"

if valid_item_name?(item_name)
  response = client.item.create(
    args: {
      board_id: 1234567890,
      item_name: item_name
    }
  )
else
  puts "Invalid item name"
end
```

## Complete Example

Create a fully configured item:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# IMPORTANT: First, get your board's column IDs:
# See "Finding Column IDs" section at the top of this guide

# Create item with all options
response = client.item.create(
  args: {
    board_id: 1234567890,  # Your board ID
    group_id: "topics",  # Your group ID
    item_name: "Q1 2024 Marketing Campaign",
    column_values: {
      status: {  # ⚠️ Replace with your status column ID
        label: "Working on it"
      },
      date4: {  # ⚠️ Replace with your date column ID
        date: "2024-03-31",
        time: "17:00:00"
      },
      people: {  # ⚠️ Replace with your people column ID
        personsAndTeams: [
          { id: 12345678, kind: "person" }  # Replace with actual user ID
        ]
      },
      text: "Launch new product marketing campaign"  # ⚠️ Replace with your text column ID
    },
    create_labels_if_missing: true
  },
  select: [
    "id",
    "name",
    "created_at",
    "state",
    {
      board: ["id", "name"],
      group: ["id", "title"],
      column_values: ["id", "text", "type"]
    }
  ]
)

if response.success?
  item = response.body.dig("data", "create_item")

  puts "\n✓ Item Created Successfully\n"
  puts "#{'=' * 50}"
  puts "Name: #{item['name']}"
  puts "ID: #{item['id']}"
  puts "Created: #{item['created_at']}"
  puts "Board: #{item.dig('board', 'name')}"
  puts "Group: #{item.dig('group', 'title')}"
  puts "\nColumn Values:"

  item["column_values"].each do |col_val|
    next if col_val["text"].nil? || col_val["text"].empty?
    puts "  • #{col_val['id']}: #{col_val['text']}"
  end

  puts "#{'=' * 50}"
else
  puts "\n✗ Failed to create item"
  puts "Status code: #{response.status}"

  if response.body["error_message"]
    puts "Error: #{response.body['error_message']}"
  end
end
```

## Create from Template

Copy an existing item structure:

```ruby
# Get the original item's structure
template_response = client.item.query(
  args: { ids: [987654321] },
  select: [
    "id",
    "name",
    {
      column_values: ["id", "text"]
    }
  ]
)

template_item = template_response.body.dig("data", "items", 0)

# Create new item with same column structure
# (You'll need to parse and reconstruct column values appropriately)
response = client.item.create(
  args: {
    board_id: 1234567890,
    item_name: "New Item from Template"
    # Add column_values based on template
  }
)
```

## Next Steps

- [Query items](/guides/items/query)
- [Update item values](/guides/items/update)
- [Work with subitems](/guides/items/subitems)
- [Update column values](/guides/columns/update-values)
- [Archive and delete items](/guides/items/delete)
