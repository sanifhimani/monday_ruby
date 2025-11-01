# Pagination

Learn how to efficiently paginate through large datasets using monday_ruby's cursor-based pagination methods.

## What is Cursor-Based Pagination?

Cursor-based pagination is a technique for retrieving large datasets in smaller, manageable chunks. Instead of using page numbers, it uses a cursor (an encoded string) that marks your position in the dataset.

**Key characteristics:**

- **Efficient**: Works well with large datasets without performance degradation
- **Consistent**: Results remain stable even when data changes during pagination
- **Time-limited**: Cursors expire after 60 minutes of inactivity
- **Configurable**: Supports page sizes from 1 to 500 items (default: 25)

**How it works:**

1. Make an initial request without a cursor to get the first page
2. The response includes items and a cursor for the next page
3. Use the cursor to fetch subsequent pages
4. When cursor is `null`, you've reached the end

## Basic Pagination

### Paginate Board Items

Fetch items from a board in pages:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: "your_api_token")

# Fetch first page (25 items by default)
response = client.board.items_page(board_ids: 12345)

items_page = response.dig("data", "boards", 0, "items_page")
items = items_page["items"]
cursor = items_page["cursor"]

puts "Fetched #{items.length} items"
puts "Cursor for next page: #{cursor}"

# Process items
items.each do |item|
  puts "Item #{item['id']}: #{item['name']}"
end
```

### Fetch Next Page

Use the cursor to get the next page:

```ruby
# Fetch second page using cursor from first page
response = client.board.items_page(
  board_ids: 12345,
  cursor: cursor
)

items_page = response.dig("data", "boards", 0, "items_page")
next_items = items_page["items"]
next_cursor = items_page["cursor"]

puts "Fetched #{next_items.length} more items"
puts "Has more pages: #{!next_cursor.nil?}"
```

### Custom Page Size

Adjust the number of items per page (max 500):

```ruby
# Fetch 100 items per page
response = client.board.items_page(
  board_ids: 12345,
  limit: 100
)

items_page = response.dig("data", "boards", 0, "items_page")
puts "Fetched #{items_page['items'].length} items"
```

## Fetch All Pages

### Iterate Through All Items

Use a loop to fetch all pages automatically:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: "your_api_token")
board_id = 12345

all_items = []
cursor = nil

loop do
  # Fetch page
  response = client.board.items_page(
    board_ids: board_id,
    limit: 100,
    cursor: cursor
  )

  items_page = response.dig("data", "boards", 0, "items_page")
  items = items_page["items"]
  cursor = items_page["cursor"]

  # Add items to collection
  all_items.concat(items)

  puts "Fetched #{items.length} items (Total: #{all_items.length})"

  # Break if no more pages
  break if cursor.nil?
end

puts "Retrieved all #{all_items.length} items from the board"
```

### With Progress Tracking

Add progress indicators for large datasets:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: "your_api_token")
board_id = 12345

all_items = []
cursor = nil
page_number = 1

loop do
  puts "Fetching page #{page_number}..."

  response = client.board.items_page(
    board_ids: board_id,
    limit: 100,
    cursor: cursor
  )

  items_page = response.dig("data", "boards", 0, "items_page")
  items = items_page["items"]
  cursor = items_page["cursor"]

  all_items.concat(items)

  puts "  -> Got #{items.length} items (Total: #{all_items.length})"

  break if cursor.nil?

  page_number += 1
end

puts "\nCompleted! Total items: #{all_items.length}"
```

## Paginate Group Items

Fetch items from specific groups with pagination:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: "your_api_token")

# Fetch first page from a group
response = client.group.items_page(
  board_ids: 12345,
  group_ids: "group_1",
  limit: 50
)

items_page = response.dig("data", "boards", 0, "groups", 0, "items_page")
items = items_page["items"]
cursor = items_page["cursor"]

puts "Fetched #{items.length} items from group"

# Fetch next page
if cursor
  next_response = client.group.items_page(
    board_ids: 12345,
    group_ids: "group_1",
    cursor: cursor
  )

  next_items_page = next_response.dig("data", "boards", 0, "groups", 0, "items_page")
  puts "Fetched #{next_items_page['items'].length} more items"
end
```

### Multiple Groups

Paginate items from multiple groups:

```ruby
# Fetch from multiple groups
response = client.group.items_page(
  board_ids: 12345,
  group_ids: ["group_1", "group_2", "group_3"],
  limit: 100
)

# Items are returned across all specified groups
boards = response.dig("data", "boards")
boards.each_with_index do |board, board_index|
  board["groups"].each_with_index do |group, group_index|
    items_page = group["items_page"]
    items = items_page["items"]

    puts "Board #{board_index}, Group #{group_index}: #{items.length} items"
  end
end
```

### Fetch All Group Items

Loop through all pages of a group:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: "your_api_token")

all_group_items = []
cursor = nil

loop do
  response = client.group.items_page(
    board_ids: 12345,
    group_ids: "topics",
    limit: 100,
    cursor: cursor
  )

  items_page = response.dig("data", "boards", 0, "groups", 0, "items_page")
  items = items_page["items"]
  cursor = items_page["cursor"]

  all_group_items.concat(items)

  break if cursor.nil?
end

puts "Total items in group: #{all_group_items.length}"
```

## Filter and Paginate

### Filter by Column Values

Use `page_by_column_values` to filter and paginate simultaneously:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: "your_api_token")

# Find all items where status is "Done" or "Working on it"
response = client.item.page_by_column_values(
  board_id: 12345,
  columns: [
    {
      column_id: "status",
      column_values: ["Done", "Working on it"]
    }
  ],
  limit: 50
)

items_page = response.dig("data", "items_page_by_column_values")
items = items_page["items"]
cursor = items_page["cursor"]

puts "Found #{items.length} items with matching status"
```

### Multiple Filter Criteria

Combine multiple column filters (uses AND logic):

```ruby
# Find high-priority items assigned to specific people
response = client.item.page_by_column_values(
  board_id: 12345,
  columns: [
    {
      column_id: "priority",
      column_values: ["High", "Critical"]
    },
    {
      column_id: "person",
      column_values: ["John Doe", "Jane Smith"]
    }
  ],
  limit: 100
)

items_page = response.dig("data", "items_page_by_column_values")
items = items_page["items"]

puts "Found #{items.length} high-priority items assigned to team members"

items.each do |item|
  puts "  - #{item['name']}"
end
```

### Paginate Filtered Results

Fetch all pages of filtered items:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: "your_api_token")
board_id = 12345

all_filtered_items = []
cursor = nil

# Define filter criteria
filter_columns = [
  {
    column_id: "status",
    column_values: ["Done"]
  }
]

# First page with filter
response = client.item.page_by_column_values(
  board_id: board_id,
  columns: filter_columns,
  limit: 100
)

items_page = response.dig("data", "items_page_by_column_values")
all_filtered_items.concat(items_page["items"])
cursor = items_page["cursor"]

# Subsequent pages (columns parameter not needed)
while cursor
  response = client.item.page_by_column_values(
    board_id: board_id,
    cursor: cursor,
    limit: 100
  )

  items_page = response.dig("data", "items_page_by_column_values")
  all_filtered_items.concat(items_page["items"])
  cursor = items_page["cursor"]

  puts "Fetched page... Total so far: #{all_filtered_items.length}"
end

puts "Total completed items: #{all_filtered_items.length}"
```

### Supported Column Types

`page_by_column_values` supports filtering on these column types:

- Checkbox
- Country
- Date
- Dropdown
- Email
- Hour
- Link
- Long Text
- Numbers
- People
- Phone
- Status
- Text
- Timeline
- World Clock

**Note:** When using multiple column filters, they are combined with AND logic. Values within a single column use ANY_OF logic.

## Advanced Techniques

### Custom Field Selection

Optimize performance by requesting only needed fields:

```ruby
# Fetch minimal fields for faster pagination
response = client.board.items_page(
  board_ids: 12345,
  limit: 500,
  select: ["id", "name"]
)

# Fetch with column values
response = client.board.items_page(
  board_ids: 12345,
  limit: 100,
  select: [
    "id",
    "name",
    { column_values: ["id", "text", "value"] }
  ]
)
```

### Handle Cursor Expiration

Cursors expire after 60 minutes. Handle expiration gracefully:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: "your_api_token")
board_id = 12345

all_items = []
cursor = nil

begin
  loop do
    response = client.board.items_page(
      board_ids: board_id,
      limit: 100,
      cursor: cursor
    )

    items_page = response.dig("data", "boards", 0, "items_page")
    items = items_page["items"]
    cursor = items_page["cursor"]

    all_items.concat(items)

    break if cursor.nil?

    # Optional: Add delay to avoid rate limits
    sleep(0.5)
  end
rescue Monday::ComplexityException => e
  puts "Rate limit exceeded. Waiting before retry..."
  sleep(60)
  retry
rescue Monday::Error => e
  puts "Error during pagination: #{e.message}"
  puts "Successfully retrieved #{all_items.length} items before error"
end

puts "Total items: #{all_items.length}"
```

### Process Items in Batches

Process items as you paginate for memory efficiency:

```ruby
require "monday_ruby"
require "csv"

client = Monday::Client.new(token: "your_api_token")
board_id = 12345

cursor = nil
total_processed = 0

# Export to CSV in batches
CSV.open("items_export.csv", "w") do |csv|
  csv << ["ID", "Name", "Created At"]

  loop do
    response = client.board.items_page(
      board_ids: board_id,
      limit: 100,
      cursor: cursor,
      select: ["id", "name", "created_at"]
    )

    items_page = response.dig("data", "boards", 0, "items_page")
    items = items_page["items"]
    cursor = items_page["cursor"]

    # Process batch
    items.each do |item|
      csv << [item["id"], item["name"], item["created_at"]]
      total_processed += 1
    end

    puts "Processed #{total_processed} items..."

    break if cursor.nil?
  end
end

puts "Export complete! Total items: #{total_processed}"
```

### Parallel Processing

Fetch items from multiple boards simultaneously:

```ruby
require "monday_ruby"
require "concurrent"

client = Monday::Client.new(token: "your_api_token")
board_ids = [12345, 67890, 11111]

# Create thread pool
pool = Concurrent::FixedThreadPool.new(3)

# Track results
results = Concurrent::Hash.new

board_ids.each do |board_id|
  pool.post do
    items = []
    cursor = nil

    loop do
      response = client.board.items_page(
        board_ids: board_id,
        limit: 100,
        cursor: cursor
      )

      items_page = response.dig("data", "boards", 0, "items_page")
      items.concat(items_page["items"])
      cursor = items_page["cursor"]

      break if cursor.nil?
    end

    results[board_id] = items
    puts "Board #{board_id}: #{items.length} items"
  end
end

# Wait for completion
pool.shutdown
pool.wait_for_termination

puts "\nTotal items across all boards: #{results.values.flatten.length}"
```

## Best Practices

### Optimal Page Size

Choose the right page size for your use case:

```ruby
# Small pages (25-50): Better for real-time processing
client.board.items_page(board_ids: 12345, limit: 25)

# Medium pages (100-200): Balanced performance
client.board.items_page(board_ids: 12345, limit: 100)

# Large pages (300-500): Minimize API calls
client.board.items_page(board_ids: 12345, limit: 500)
```

**Guidelines:**

- Use **25-50** items when processing data in real-time
- Use **100-200** items for balanced performance
- Use **300-500** items to minimize API calls for large datasets
- Never exceed 500 (API limit)

### Error Handling

Always handle pagination errors:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: "your_api_token")

all_items = []
cursor = nil
retry_count = 0
max_retries = 3

loop do
  begin
    response = client.board.items_page(
      board_ids: 12345,
      limit: 100,
      cursor: cursor
    )

    items_page = response.dig("data", "boards", 0, "items_page")
    items = items_page["items"]
    cursor = items_page["cursor"]

    all_items.concat(items)
    retry_count = 0 # Reset on success

    break if cursor.nil?

  rescue Monday::ComplexityException => e
    # Rate limit exceeded
    if retry_count < max_retries
      retry_count += 1
      puts "Rate limited. Retry #{retry_count}/#{max_retries} in 60s..."
      sleep(60)
      retry
    else
      puts "Max retries exceeded. Collected #{all_items.length} items."
      break
    end

  rescue Monday::AuthorizationException => e
    puts "Authorization error: #{e.message}"
    break

  rescue Monday::Error => e
    puts "Unexpected error: #{e.message}"
    break
  end
end

puts "Total items retrieved: #{all_items.length}"
```

### Cursor Storage

Store cursors for resumable pagination:

```ruby
require "monday_ruby"
require "json"

client = Monday::Client.new(token: "your_api_token")
board_id = 12345

# Load saved cursor
cursor = nil
if File.exist?("pagination_state.json")
  state = JSON.parse(File.read("pagination_state.json"))
  cursor = state["cursor"]
  puts "Resuming from saved cursor"
end

# Paginate
loop do
  response = client.board.items_page(
    board_ids: board_id,
    limit: 100,
    cursor: cursor
  )

  items_page = response.dig("data", "boards", 0, "items_page")
  items = items_page["items"]
  cursor = items_page["cursor"]

  # Process items
  items.each do |item|
    puts "Processing: #{item['name']}"
    # Your processing logic here
  end

  # Save cursor for resume capability
  if cursor
    File.write("pagination_state.json", JSON.dump({ cursor: cursor }))
  else
    File.delete("pagination_state.json") if File.exist?("pagination_state.json")
  end

  break if cursor.nil?
end

puts "Pagination complete"
```

### Rate Limiting

Add delays to avoid hitting rate limits:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: "your_api_token")

all_items = []
cursor = nil

loop do
  response = client.board.items_page(
    board_ids: 12345,
    limit: 100,
    cursor: cursor
  )

  items_page = response.dig("data", "boards", 0, "items_page")
  items = items_page["items"]
  cursor = items_page["cursor"]

  all_items.concat(items)

  break if cursor.nil?

  # Add delay between requests
  sleep(0.5) # 500ms delay
end

puts "Total items: #{all_items.length}"
```

## Common Patterns

### Count Total Items

Count items without storing them all:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: "your_api_token")

total_count = 0
cursor = nil

loop do
  response = client.board.items_page(
    board_ids: 12345,
    limit: 500,
    cursor: cursor,
    select: ["id"] # Minimal data
  )

  items_page = response.dig("data", "boards", 0, "items_page")
  total_count += items_page["items"].length
  cursor = items_page["cursor"]

  break if cursor.nil?
end

puts "Total items on board: #{total_count}"
```

### Find Specific Item

Stop pagination when you find what you need:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: "your_api_token")

target_name = "Project Alpha"
found_item = nil
cursor = nil

loop do
  response = client.board.items_page(
    board_ids: 12345,
    limit: 100,
    cursor: cursor
  )

  items_page = response.dig("data", "boards", 0, "items_page")
  items = items_page["items"]
  cursor = items_page["cursor"]

  # Search in current page
  found_item = items.find { |item| item["name"] == target_name }

  break if found_item || cursor.nil?
end

if found_item
  puts "Found item: #{found_item['id']}"
else
  puts "Item not found"
end
```

### Aggregate Data

Calculate statistics across all pages:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: "your_api_token")

stats = {
  total: 0,
  by_group: Hash.new(0)
}

cursor = nil

loop do
  response = client.board.items_page(
    board_ids: 12345,
    limit: 100,
    cursor: cursor,
    select: ["id", "name", { group: ["id", "title"] }]
  )

  items_page = response.dig("data", "boards", 0, "items_page")
  items = items_page["items"]
  cursor = items_page["cursor"]

  items.each do |item|
    stats[:total] += 1
    group_id = item.dig("group", "id")
    stats[:by_group][group_id] += 1 if group_id
  end

  break if cursor.nil?
end

puts "Total items: #{stats[:total]}"
puts "\nItems per group:"
stats[:by_group].each do |group_id, count|
  puts "  #{group_id}: #{count}"
end
```

## Troubleshooting

### Cursor Expired

**Problem:** Cursor returns an error after 60 minutes.

**Solution:** Restart pagination from the beginning or implement cursor storage.

```ruby
begin
  response = client.board.items_page(
    board_ids: 12345,
    cursor: old_cursor
  )
rescue Monday::Error => e
  if e.message.include?("cursor")
    puts "Cursor expired. Restarting pagination..."
    cursor = nil
    retry
  end
end
```

### Empty Results

**Problem:** Getting empty results when items exist.

**Solution:** Check your filter criteria and board ID.

```ruby
response = client.item.page_by_column_values(
  board_id: 12345,
  columns: [
    {
      column_id: "status",
      column_values: ["Done"]
    }
  ]
)

items = response.dig("data", "items_page_by_column_values", "items")

if items.empty?
  puts "No items match the filter criteria"
  puts "Check:"
  puts "  - Board ID is correct"
  puts "  - Column ID exists"
  puts "  - Column values match exactly"
end
```

### Rate Limits

**Problem:** Hitting API rate limits during pagination.

**Solution:** Add delays and implement retry logic.

```ruby
require "monday_ruby"

def paginate_with_retry(client, board_id, max_retries: 3)
  all_items = []
  cursor = nil
  retry_count = 0

  loop do
    begin
      response = client.board.items_page(
        board_ids: board_id,
        limit: 100,
        cursor: cursor
      )

      items_page = response.dig("data", "boards", 0, "items_page")
      all_items.concat(items_page["items"])
      cursor = items_page["cursor"]
      retry_count = 0

      break if cursor.nil?

      sleep(0.5) # Rate limit protection

    rescue Monday::ComplexityException => e
      if retry_count < max_retries
        retry_count += 1
        wait_time = 60 * retry_count
        puts "Rate limited. Waiting #{wait_time}s..."
        sleep(wait_time)
        retry
      else
        puts "Max retries exceeded"
        break
      end
    end
  end

  all_items
end

client = Monday::Client.new(token: "your_api_token")
items = paginate_with_retry(client, 12345)
puts "Retrieved #{items.length} items"
```

## Next Steps

- Learn about [Error Handling](./errors) for robust pagination
- Explore [Performance Optimization](/explanation/best-practices/performance) for better query performance
- Check out [Batch Operations](./batch) for processing paginated data
