# Query Items

Retrieve and filter items from your monday.com boards.

## Basic Query

Get items with default fields (ID, name, created_at):

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.item.query

if response.success?
  items = response.body.dig("data", "items")
  puts "Found #{items.length} items"
end
```

## Query by IDs

Retrieve specific items:

```ruby
response = client.item.query(
  args: { ids: [987654321, 987654322, 987654323] }
)

if response.success?
  items = response.body.dig("data", "items")

  items.each do |item|
    puts "#{item['name']} (ID: #{item['id']})"
  end
end
```

### Single Item

Query one item by ID:

```ruby
response = client.item.query(
  args: { ids: "987654321" }
)

if response.success?
  items = response.body.dig("data", "items")
  item = items.first

  puts "Item: #{item['name']}"
  puts "Created: #{item['created_at']}"
end
```

## Query with Pagination

Use limit and page for basic pagination:

```ruby
# First page
response = client.item.query(
  args: {
    limit: 25,
    page: 1
  }
)

if response.success?
  items = response.body.dig("data", "items")
  puts "Page 1: #{items.length} items"
end

# Next page
response = client.item.query(
  args: {
    limit: 25,
    page: 2
  }
)
```

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Pagination Limits</span>
The `items` query has a maximum return limit. For large datasets, use [`items_page`](/guides/advanced/pagination) or [`page_by_column_values`](#filter-by-column-values) instead.
:::

## Sort Results

Order items by creation date:

### Newest First

```ruby
response = client.item.query(
  args: { newest_first: true }
)

if response.success?
  items = response.body.dig("data", "items")

  puts "Most recent items:"
  items.first(5).each do |item|
    puts "  • #{item['name']} (#{item['created_at']})"
  end
end
```

### Oldest First

```ruby
response = client.item.query(
  args: { newest_first: false }
)
```

## Custom Fields Selection

Request specific fields:

### Basic Fields

```ruby
response = client.item.query(
  args: { ids: [987654321] },
  select: ["id", "name", "created_at", "state", "url"]
)

if response.success?
  item = response.body.dig("data", "items", 0)

  puts "Name: #{item['name']}"
  puts "State: #{item['state']}"
  puts "URL: #{item['url']}"
  puts "Created: #{item['created_at']}"
end
```

### With Board Information

```ruby
response = client.item.query(
  args: { ids: [987654321] },
  select: [
    "id",
    "name",
    {
      board: ["id", "name", "url"]
    }
  ]
)

if response.success?
  item = response.body.dig("data", "items", 0)
  board = item.dig("board")

  puts "Item: #{item['name']}"
  puts "Board: #{board['name']}"
  puts "Board URL: #{board['url']}"
end
```

## Query with Column Values

Get item column data:

```ruby
response = client.item.query(
  args: { ids: [987654321] },
  select: [
    "id",
    "name",
    {
      column_values: ["id", "text", "type", "value"]
    }
  ]
)

if response.success?
  item = response.body.dig("data", "items", 0)

  puts "Item: #{item['name']}"
  puts "\nColumn Values:"

  item["column_values"].each do |col_val|
    next if col_val["text"].nil? || col_val["text"].empty?
    puts "  • #{col_val['id']}: #{col_val['text']} (#{col_val['type']})"
  end
end
```

**Example output:**
```
Item: Marketing Campaign
Column Values:
  • status__1: Done (color)
  • date: 2024-12-31 (date)
  • people: John Doe (people)
  • text: High Priority (text)
```

## Query with Group Information

Get the group (section) an item belongs to:

```ruby
response = client.item.query(
  args: { ids: [987654321] },
  select: [
    "id",
    "name",
    {
      group: ["id", "title", "color"]
    }
  ]
)

if response.success?
  item = response.body.dig("data", "items", 0)
  group = item.dig("group")

  puts "Item: #{item['name']}"
  puts "Group: #{group['title']} (#{group['color']})"
end
```

## Query with Subitems

Retrieve an item's subitems:

```ruby
response = client.item.query(
  args: { ids: [987654321] },
  select: [
    "id",
    "name",
    {
      subitems: ["id", "name", "state"]
    }
  ]
)

if response.success?
  item = response.body.dig("data", "items", 0)

  puts "Item: #{item['name']}"
  puts "Subitems:"

  item["subitems"].each do |subitem|
    puts "  • #{subitem['name']} (#{subitem['state']})"
  end
end
```

## Query with Updates

Get item update threads:

```ruby
response = client.item.query(
  args: { ids: [987654321] },
  select: [
    "id",
    "name",
    {
      updates: ["id", "body", "created_at"]
    }
  ]
)

if response.success?
  item = response.body.dig("data", "items", 0)

  puts "Item: #{item['name']}"
  puts "Updates: #{item['updates'].length}"

  item["updates"].first(3).each do |update|
    puts "\n  [#{update['created_at']}]"
    puts "  #{update['body']}"
  end
end
```

## Filter by Column Values

Use `page_by_column_values` for advanced filtering:

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Column IDs are Board-Specific</span>
**You must use your board's actual column IDs for filtering.** Query your board first to get column IDs:

```ruby
response = client.board.query(
  args: { ids: [1234567890] },
  select: ["id", { columns: ["id", "title", "type"] }]
)

board = response.body.dig("data", "boards", 0)
board["columns"].each do |col|
  puts "#{col['title']}: '#{col['id']}' (#{col['type']})"
end
```

Use the exact column IDs (e.g., `status_1`, `date4`) from the output above.
:::

### Single Column Filter

```ruby
# ⚠️ Replace 'status' with your actual status column ID
response = client.item.page_by_column_values(
  board_id: 1234567890,
  columns: [
    { column_id: "status", column_values: ["Done"] }  # Your column ID
  ],
  limit: 50
)

if response.success?
  items_page = response.body.dig("data", "items_page_by_column_values")
  items = items_page["items"]
  cursor = items_page["cursor"]

  puts "Found #{items.length} items with status 'Done'"

  items.each do |item|
    puts "  • #{item['name']}"
  end
end
```

### Multiple Column Filters (AND Logic)

Filter by multiple columns - all conditions must match:

```ruby
# ⚠️ Replace 'status' and 'priority' with your actual column IDs
response = client.item.page_by_column_values(
  board_id: 1234567890,
  columns: [
    { column_id: "status", column_values: ["Done"] },  # Your status column ID
    { column_id: "priority", column_values: ["High"] }  # Your priority column ID
  ]
)

if response.success?
  items_page = response.body.dig("data", "items_page_by_column_values")
  items = items_page["items"]

  puts "High priority items that are done:"
  items.each do |item|
    puts "  • #{item['name']}"
  end
end
```

### Multiple Values (OR Logic Within Column)

Match any of several values in a column:

```ruby
response = client.item.page_by_column_values(
  board_id: 1234567890,
  columns: [
    { column_id: "status", column_values: ["Done", "Working on it", "Stuck"] }
  ]
)

if response.success?
  items_page = response.body.dig("data", "items_page_by_column_values")
  items = items_page["items"]

  puts "Items in active states: #{items.length}"
end
```

### With Cursor Pagination

Paginate through filtered results:

```ruby
def fetch_all_filtered_items(client, board_id, columns)
  all_items = []
  cursor = nil

  loop do
    response = client.item.page_by_column_values(
      board_id: board_id,
      columns: cursor.nil? ? columns : nil,
      cursor: cursor,
      limit: 50
    )

    break unless response.success?

    items_page = response.body.dig("data", "items_page_by_column_values")
    items = items_page["items"]
    break if items.empty?

    all_items.concat(items)
    cursor = items_page["cursor"]
    break if cursor.nil?

    puts "Fetched #{items.length} items, cursor: #{cursor[0..20]}..."
  end

  all_items
end

# Usage
items = fetch_all_filtered_items(
  client,
  1234567890,
  [{ column_id: "status", column_values: ["Done"] }]
)

puts "\nTotal filtered items: #{items.length}"
```

## Search Items by Name

Find items matching a name pattern:

```ruby
def find_items_by_name(client, board_id, search_term)
  # Note: 'name' is a standard column ID that exists on all boards
  response = client.item.page_by_column_values(
    board_id: board_id,
    columns: [
      { column_id: "name", column_values: [search_term] }
    ],
    limit: 100
  )

  return [] unless response.success?

  items_page = response.body.dig("data", "items_page_by_column_values")
  items_page["items"]
end

# Usage
matching_items = find_items_by_name(client, 1234567890, "Marketing")

puts "Items matching 'Marketing':"
matching_items.each do |item|
  puts "  • #{item['name']}"
end
```

## Get Item Count

Count items on a board:

```ruby
response = client.item.query(
  args: {
    limit: 1  # We only need the count, not all items
  },
  select: ["id"]
)

if response.success?
  items = response.body.dig("data", "items")
  puts "Total items: #{items.length}"
end
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Better Counting</span>
For accurate counts on boards with many items, use `board.items_page` with minimal select fields instead.
:::

## Complete Example

Comprehensive item querying:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# Query with detailed fields
response = client.item.query(
  args: {
    ids: [987654321, 987654322],
    newest_first: true
  },
  select: [
    "id",
    "name",
    "created_at",
    "state",
    "url",
    {
      board: ["id", "name"],
      group: ["id", "title"],
      column_values: ["id", "text", "type"],
      creator: ["id", "name", "email"]
    }
  ]
)

if response.success?
  items = response.body.dig("data", "items")

  puts "\n📝 Query Results\n#{'=' * 60}\n"

  items.each do |item|
    board = item.dig("board")
    group = item.dig("group")
    creator = item.dig("creator")

    puts "\n#{item['name']}"
    puts "  ID: #{item['id']}"
    puts "  State: #{item['state']}"
    puts "  Board: #{board&.dig('name')}"
    puts "  Group: #{group&.dig('title')}"
    puts "  Creator: #{creator&.dig('name')} (#{creator&.dig('email')})"
    puts "  Created: #{item['created_at']}"
    puts "  URL: #{item['url']}"

    puts "\n  Column Values:"
    item["column_values"].each do |col_val|
      next if col_val["text"].nil? || col_val["text"].empty?
      puts "    • #{col_val['id']}: #{col_val['text']}"
    end
  end

  puts "\n#{'=' * 60}"
  puts "Total: #{items.length} items"
else
  puts "❌ Failed to query items"
  puts "Status: #{response.status}"
end
```

## Export Items to CSV

Query and export items:

```ruby
require "csv"

def export_items_to_csv(client, board_id, filename)
  # Query items with column values
  response = client.item.page_by_column_values(
    board_id: board_id,
    columns: nil,
    limit: 500,
    select: [
      "id",
      "name",
      "created_at",
      {
        column_values: ["id", "text"]
      }
    ]
  )

  return unless response.success?

  items_page = response.body.dig("data", "items_page_by_column_values")
  items = items_page["items"]

  CSV.open(filename, "w") do |csv|
    # Header
    csv << ["ID", "Name", "Created At", "Column Values"]

    # Data
    items.each do |item|
      column_data = item["column_values"]
        .map { |cv| "#{cv['id']}: #{cv['text']}" }
        .join("; ")

      csv << [
        item["id"],
        item["name"],
        item["created_at"],
        column_data
      ]
    end
  end

  puts "✓ Exported #{items.length} items to #{filename}"
end

# Usage
export_items_to_csv(client, 1234567890, "items_export.csv")
```

## Next Steps

- [Create items](/guides/items/create)
- [Update item values](/guides/items/update)
- [Advanced pagination](/guides/advanced/pagination)
- [Filter with complex queries](/guides/advanced/complex-queries)
- [Work with column values](/guides/columns/query)
