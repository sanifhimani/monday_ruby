# Work with Items in Groups

Learn how to move items between groups and retrieve paginated items from groups efficiently.

## Move Items Between Groups

Reorganize items by moving them to different groups on the same board.

### Basic Item Move

Move an item to a different group:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.group.move_item(
  args: {
    item_id: 987654321,
    group_id: "group_mkx1yn2n"
  }
)

if response.success?
  item = response.body.dig("data", "move_item_to_group")
  puts "✓ Moved item #{item['id']} to new group"
end
```

### Move with Group Information

Confirm the new group after moving:

```ruby
response = client.group.move_item(
  args: {
    item_id: 987654321,
    group_id: "group_mkx1yn2n"
  },
  select: [
    "id",
    "name",
    {
      group: ["id", "title"]
    }
  ]
)

if response.success?
  item = response.body.dig("data", "move_item_to_group")
  group = item["group"]

  puts "✓ Item: #{item['name']}"
  puts "  Moved to: #{group['title']} (#{group['id']})"
end
```

**Output:**
```
✓ Item: Order #1234
  Moved to: Completed Orders (group_mkx1yn2n)
```

### Move Multiple Items

Batch move items to a group:

```ruby
item_ids = [111, 222, 333, 444, 555]
destination_group = "group_mkx1yn2n"

puts "Moving #{item_ids.length} items..."

item_ids.each do |item_id|
  response = client.group.move_item(
    args: {
      item_id: item_id,
      group_id: destination_group
    }
  )

  if response.success?
    puts "✓ Moved item #{item_id}"
  else
    puts "✗ Failed to move item #{item_id}"
  end
end

puts "Complete!"
```

### Organize Items by Status

Move items based on their status:

```ruby
# Get items from board
board_response = client.board.items_page(
  board_ids: 123,
  limit: 100,
  select: [
    "id",
    "name",
    {
      column_values: ["id", "text"]
    }
  ]
)

items = board_response.body.dig("data", "boards", 0, "items_page", "items")

# Move completed items to "Done" group
done_group_id = "group_done123"

items.each do |item|
  status_column = item["column_values"].find { |cv| cv["id"] == "status" }

  if status_column && status_column["text"] == "Done"
    response = client.group.move_item(
      args: {
        item_id: item["id"],
        group_id: done_group_id
      }
    )

    puts "✓ Moved #{item['name']} to Done group" if response.success?
  end
end
```

## Paginated Item Retrieval

Efficiently retrieve large numbers of items from groups using cursor-based pagination.

### Basic Pagination

Retrieve first page of items:

```ruby
response = client.group.items_page(
  board_ids: 123,
  group_ids: "group_mkx1yn2n",
  limit: 50
)

if response.success?
  items_page = response.body.dig("data", "boards", 0, "groups", 0, "items_page")
  items = items_page["items"]
  cursor = items_page["cursor"]

  puts "Retrieved #{items.length} items"
  puts "More pages available: #{!cursor.nil?}"
end
```

**Output:**
```
Retrieved 50 items
More pages available: true
```

### Fetch All Pages

Loop through all pages using cursors:

```ruby
board_id = 123
group_id = "group_mkx1yn2n"
all_items = []
cursor = nil

loop do
  response = client.group.items_page(
    board_ids: board_id,
    group_ids: group_id,
    limit: 100,
    cursor: cursor
  )

  items_page = response.body.dig("data", "boards", 0, "groups", 0, "items_page")
  items = items_page["items"]
  cursor = items_page["cursor"]

  all_items.concat(items)
  puts "Fetched #{items.length} items (total: #{all_items.length})"

  break if cursor.nil?  # No more pages
end

puts "\n✓ Retrieved all #{all_items.length} items"
```

**Output:**
```
Fetched 100 items (total: 100)
Fetched 100 items (total: 200)
Fetched 47 items (total: 247)

✓ Retrieved all 247 items
```

### Multiple Groups

Retrieve items from multiple groups:

```ruby
response = client.group.items_page(
  board_ids: 123,
  group_ids: ["group_1", "group_2", "group_3"],
  limit: 50
)

if response.success?
  boards = response.body.dig("data", "boards")

  boards.each do |board|
    board["groups"].each do |group|
      items = group["items_page"]["items"]
      cursor = group["items_page"]["cursor"]

      puts "Group has #{items.length} items"
      puts "More pages: #{!cursor.nil?}"
    end
  end
end
```

### Multiple Boards and Groups

Query across multiple boards:

```ruby
response = client.group.items_page(
  board_ids: [123, 456],
  group_ids: ["group_mkx1yn2n", "group_abc123"],
  limit: 100
)

boards = response.body.dig("data", "boards")

boards.each_with_index do |board, board_index|
  board["groups"].each_with_index do |group, group_index|
    items = group["items_page"]["items"]
    puts "Board #{board_index + 1}, Group #{group_index + 1}: #{items.length} items"
  end
end
```

## Filter Items with Query Params

Retrieve only items matching specific criteria.

### Filter by Column Value

Get items with specific status:

```ruby
response = client.group.items_page(
  board_ids: 123,
  group_ids: "group_mkx1yn2n",
  limit: 100,
  query_params: {
    rules: [
      { column_id: "status", compare_value: [1] }  # Status index 1
    ],
    operator: :and
  }
)

items = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "items")
puts "Found #{items.length} items with selected status"
```

### Multiple Filter Rules

Combine multiple conditions:

```ruby
response = client.group.items_page(
  board_ids: 123,
  group_ids: "group_mkx1yn2n",
  limit: 100,
  query_params: {
    rules: [
      { column_id: "status", compare_value: [1, 2] },      # Status 1 or 2
      { column_id: "priority", compare_value: [0] }        # High priority
    ],
    operator: :and  # Items must match ALL rules
  }
)

items = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "items")
puts "Found #{items.length} high-priority items in progress"
```

### Filter with OR Operator

Match items meeting any condition:

```ruby
response = client.group.items_page(
  board_ids: 123,
  group_ids: "group_mkx1yn2n",
  limit: 100,
  query_params: {
    rules: [
      { column_id: "status", compare_value: [0] },    # Not started
      { column_id: "status", compare_value: [5] }     # Stuck
    ],
    operator: :or  # Items matching ANY rule
  }
)

items = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "items")
puts "Found #{items.length} items needing attention"
```

### Filter by Text Column

Search by item name or text column:

```ruby
response = client.group.items_page(
  board_ids: 123,
  group_ids: "group_mkx1yn2n",
  limit: 100,
  query_params: {
    rules: [
      { column_id: "name", compare_value: ["Test Item 1"] }
    ],
    operator: :and
  }
)

items = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "items")
items.each do |item|
  puts "• #{item['name']}"
end
```

## Custom Field Selection

Retrieve specific fields to reduce response size and improve performance.

### Basic Fields

Get essential item information:

```ruby
response = client.group.items_page(
  board_ids: 123,
  group_ids: "group_mkx1yn2n",
  limit: 50,
  select: ["id", "name", "created_at", "updated_at"]
)

items = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "items")

items.each do |item|
  puts "#{item['name']} (created: #{item['created_at']})"
end
```

### Include Column Values

Get item data with column values:

```ruby
response = client.group.items_page(
  board_ids: 123,
  group_ids: "group_mkx1yn2n",
  limit: 50,
  select: [
    "id",
    "name",
    {
      column_values: ["id", "text", "value"]
    }
  ]
)

items = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "items")

items.each do |item|
  puts "\nItem: #{item['name']}"
  item["column_values"].each do |cv|
    puts "  #{cv['id']}: #{cv['text']}"
  end
end
```

**Output:**
```
Item: Order #1234
  status: In Progress
  person: John Doe
  date: 2024-01-15

Item: Order #1235
  status: Done
  person: Jane Smith
  date: 2024-01-16
```

### Include Related Objects

Get group and board information with items:

```ruby
response = client.group.items_page(
  board_ids: 123,
  group_ids: "group_mkx1yn2n",
  limit: 50,
  select: [
    "id",
    "name",
    {
      group: ["id", "title", "color"]
    },
    {
      board: ["id", "name"]
    }
  ]
)

items = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "items")

items.each do |item|
  puts "#{item['name']} in #{item['group']['title']} on #{item['board']['name']}"
end
```

## Cursor Expiration

Cursors expire after 60 minutes. Handle expired cursors gracefully:

```ruby
def fetch_all_items(client, board_id, group_id)
  all_items = []
  cursor = nil
  max_retries = 3
  retry_count = 0

  loop do
    begin
      response = client.group.items_page(
        board_ids: board_id,
        group_ids: group_id,
        limit: 100,
        cursor: cursor
      )

      items_page = response.body.dig("data", "boards", 0, "groups", 0, "items_page")
      items = items_page["items"]
      cursor = items_page["cursor"]

      all_items.concat(items)
      puts "Fetched #{items.length} items"

      retry_count = 0  # Reset on success
      break if cursor.nil?

    rescue Monday::Error => e
      retry_count += 1

      if retry_count <= max_retries
        puts "Error: #{e.message}. Retrying from start..."
        cursor = nil  # Start over
        all_items = []
      else
        puts "Max retries reached. Failed to fetch all items."
        raise
      end
    end
  end

  all_items
end

# Usage
items = fetch_all_items(client, 123, "group_mkx1yn2n")
puts "Total items: #{items.length}"
```

## Performance Tips

Optimize pagination for better performance:

### Use Appropriate Page Sizes

```ruby
# For quick scans - smaller pages
response = client.group.items_page(
  board_ids: 123,
  group_ids: "group_mkx1yn2n",
  limit: 25  # Faster initial response
)

# For bulk processing - larger pages
response = client.group.items_page(
  board_ids: 123,
  group_ids: "group_mkx1yn2n",
  limit: 500  # Maximum, fewer requests
)
```

### Request Only Needed Fields

```ruby
# Good - only necessary fields
response = client.group.items_page(
  board_ids: 123,
  group_ids: "group_mkx1yn2n",
  limit: 100,
  select: ["id", "name"]  # Minimal payload
)

# Avoid - requesting everything
response = client.group.items_page(
  board_ids: 123,
  group_ids: "group_mkx1yn2n",
  limit: 100,
  select: [
    "id", "name", "created_at", "updated_at", "creator_id", "state",
    { column_values: ["id", "text", "value", "additional_info"] },
    { board: ["id", "name", "description", "state", "board_kind"] }
  ]  # Large payload, slower
)
```

## Complete Example

Full workflow for working with group items:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

board_id = 123
in_progress_group = "group_progress"
done_group = "group_done"

# 1. Get all items from "In Progress" group
puts "=== Fetching In Progress Items ==="
all_items = []
cursor = nil

loop do
  response = client.group.items_page(
    board_ids: board_id,
    group_ids: in_progress_group,
    limit: 100,
    cursor: cursor,
    select: [
      "id",
      "name",
      { column_values: ["id", "text"] }
    ]
  )

  items_page = response.body.dig("data", "boards", 0, "groups", 0, "items_page")
  items = items_page["items"]
  cursor = items_page["cursor"]

  all_items.concat(items)
  break if cursor.nil?
end

puts "Found #{all_items.length} items in progress"

# 2. Identify completed items
completed_items = all_items.select do |item|
  status = item["column_values"].find { |cv| cv["id"] == "status" }
  status && status["text"] == "Done"
end

puts "\n=== Moving Completed Items ==="
puts "#{completed_items.length} items are done"

# 3. Move completed items to Done group
completed_items.each do |item|
  response = client.group.move_item(
    args: {
      item_id: item["id"],
      group_id: done_group
    }
  )

  if response.success?
    puts "✓ Moved: #{item['name']}"
  else
    puts "✗ Failed: #{item['name']}"
  end
end

# 4. Verify Done group
puts "\n=== Verifying Done Group ==="
response = client.group.items_page(
  board_ids: board_id,
  group_ids: done_group,
  limit: 100
)

done_items = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "items")
puts "Done group now has #{done_items.length} items"

puts "\n=== Complete ==="
```

## Next Steps

- [Manage groups](/guides/groups/manage)
- [Create items](/guides/items/create)
- [Update item values](/guides/columns/update-values)
- [Query items](/guides/items/query)
