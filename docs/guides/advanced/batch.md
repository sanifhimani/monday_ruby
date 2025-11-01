# Batch Operations

Efficiently perform bulk create, update, and delete operations on monday.com boards.

## Overview

Since monday_ruby doesn't provide native batch API endpoints, batch operations involve looping through items with proper rate limiting, error handling, and progress tracking. This guide shows production-ready patterns for bulk operations.

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Rate Limiting Required</span>
Always include delays between requests when performing batch operations to avoid hitting monday.com's API rate limits.
:::

## Bulk Create Operations

### Create Multiple Items

Create multiple items efficiently with rate limiting:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

def bulk_create_items(client, board_id, items_data, delay: 0.3)
  results = {
    created: [],
    failed: []
  }

  puts "Creating #{items_data.length} items..."

  items_data.each_with_index do |item_data, index|
    response = client.item.create(
      args: {
        board_id: board_id,
        item_name: item_data[:name],
        column_values: item_data[:columns] || {}
      }
    )

    if response.success?
      item = response.body.dig("data", "create_item")
      results[:created] << item
      puts "[#{index + 1}/#{items_data.length}] ✓ Created: #{item['name']}"
    else
      results[:failed] << { name: item_data[:name], error: response.body }
      puts "[#{index + 1}/#{items_data.length}] ✗ Failed: #{item_data[:name]}"
    end

    # Rate limiting delay
    sleep(delay) unless index == items_data.length - 1
  end

  results
end

# Usage
items = [
  { name: "Marketing Campaign Q1" },
  { name: "Product Launch Planning" },
  { name: "Customer Research" },
  { name: "Website Redesign" },
  { name: "Social Media Strategy" }
]

results = bulk_create_items(client, 1234567890, items)

puts "\n" + "=" * 50
puts "Created: #{results[:created].length}"
puts "Failed: #{results[:failed].length}"
```

**Output:**
```
Creating 5 items...
[1/5] ✓ Created: Marketing Campaign Q1
[2/5] ✓ Created: Product Launch Planning
[3/5] ✓ Created: Customer Research
[4/5] ✓ Created: Website Redesign
[5/5] ✓ Created: Social Media Strategy

==================================================
Created: 5
Failed: 0
```

### Create with Column Values

Bulk create items with column values:

```ruby
require "json"

def bulk_create_with_values(client, board_id, items_data, delay: 0.3)
  results = { created: [], failed: [] }

  items_data.each_with_index do |data, index|
    # ⚠️ Replace column IDs with your board's actual column IDs
    column_values = {
      status: { label: data[:status] || "Not Started" },
      date4: { date: data[:due_date] } if data[:due_date],
      text: data[:description] || ""
    }.compact

    response = client.item.create(
      args: {
        board_id: board_id,
        item_name: data[:name],
        column_values: JSON.generate(column_values),
        create_labels_if_missing: true
      }
    )

    if response.success?
      item = response.body.dig("data", "create_item")
      results[:created] << item
      puts "[#{index + 1}/#{items_data.length}] ✓ #{item['name']}"
    else
      results[:failed] << data
      puts "[#{index + 1}/#{items_data.length}] ✗ #{data[:name]}"
    end

    sleep(delay) unless index == items_data.length - 1
  end

  results
end

# Usage
tasks = [
  {
    name: "Design Homepage",
    status: "Working on it",
    due_date: "2024-12-15",
    description: "Create new homepage mockups"
  },
  {
    name: "Implement API",
    status: "Not Started",
    due_date: "2024-12-20",
    description: "Build REST API endpoints"
  },
  {
    name: "Write Tests",
    status: "Not Started",
    due_date: "2024-12-22",
    description: "Unit and integration tests"
  }
]

results = bulk_create_with_values(client, 1234567890, tasks)
puts "\nCreated #{results[:created].length} items with values"
```

### Create Multiple Boards

Create multiple boards efficiently:

```ruby
def bulk_create_boards(client, boards_data, delay: 0.5)
  results = { created: [], failed: [] }

  puts "Creating #{boards_data.length} boards..."

  boards_data.each_with_index do |board_data, index|
    response = client.board.create(
      args: {
        board_name: board_data[:name],
        board_kind: board_data[:kind] || "public",
        workspace_id: board_data[:workspace_id]
      }
    )

    if response.success?
      board = response.body.dig("data", "create_board")
      results[:created] << board
      puts "[#{index + 1}/#{boards_data.length}] ✓ Created: #{board['name']}"
    else
      results[:failed] << board_data
      puts "[#{index + 1}/#{boards_data.length}] ✗ Failed: #{board_data[:name]}"
    end

    sleep(delay) unless index == boards_data.length - 1
  end

  results
end

# Usage
boards = [
  { name: "Marketing Q1 2024", workspace_id: 12345 },
  { name: "Product Roadmap", workspace_id: 12345 },
  { name: "Customer Feedback", workspace_id: 12345 }
]

results = bulk_create_boards(client, boards)
puts "\nCreated #{results[:created].length} boards"
```

### Create Multiple Columns

Add multiple columns to a board:

```ruby
def bulk_create_columns(client, board_id, columns_data, delay: 0.3)
  results = { created: [], failed: [] }

  columns_data.each_with_index do |col_data, index|
    response = client.column.create(
      args: {
        board_id: board_id,
        title: col_data[:title],
        column_type: col_data[:type]
      }
    )

    if response.success?
      column = response.body.dig("data", "create_column")
      results[:created] << column
      puts "[#{index + 1}/#{columns_data.length}] ✓ Created: #{column['title']}"
    else
      results[:failed] << col_data
      puts "[#{index + 1}/#{columns_data.length}] ✗ Failed: #{col_data[:title]}"
    end

    sleep(delay) unless index == columns_data.length - 1
  end

  results
end

# Usage
columns = [
  { title: "Priority", type: "status" },
  { title: "Assignee", type: "people" },
  { title: "Due Date", type: "date" },
  { title: "Progress", type: "numbers" },
  { title: "Notes", type: "text" }
]

results = bulk_create_columns(client, 1234567890, columns)
puts "\nCreated #{results[:created].length} columns"
```

## Bulk Update Operations

### Update Multiple Items

Update multiple items with the same values:

```ruby
def bulk_update_items(client, board_id, item_ids, column_values, delay: 0.3)
  results = { updated: [], failed: [] }

  puts "Updating #{item_ids.length} items..."

  item_ids.each_with_index do |item_id, index|
    response = client.column.change_multiple_values(
      args: {
        board_id: board_id,
        item_id: item_id,
        column_values: JSON.generate(column_values)
      }
    )

    if response.success?
      item = response.body.dig("data", "change_multiple_column_values")
      results[:updated] << item
      puts "[#{index + 1}/#{item_ids.length}] ✓ Updated: #{item['name']}"
    else
      results[:failed] << item_id
      puts "[#{index + 1}/#{item_ids.length}] ✗ Failed: #{item_id}"
    end

    sleep(delay) unless index == item_ids.length - 1
  end

  results
end

# Usage: Mark all items as complete
item_ids = [987654321, 987654322, 987654323, 987654324]

# ⚠️ Replace column IDs with your board's actual column IDs
updates = {
  status: { label: "Done" },
  date4: { date: Date.today.to_s },
  text: "Bulk completed"
}

results = bulk_update_items(client, 1234567890, item_ids, updates)
puts "\nUpdated #{results[:updated].length} items"
```

### Update with Different Values

Update each item with unique values:

```ruby
def bulk_update_different(client, board_id, updates_data, delay: 0.3)
  results = { updated: [], failed: [] }

  updates_data.each_with_index do |update, index|
    response = client.column.change_multiple_values(
      args: {
        board_id: board_id,
        item_id: update[:item_id],
        column_values: JSON.generate(update[:values])
      }
    )

    if response.success?
      item = response.body.dig("data", "change_multiple_column_values")
      results[:updated] << item
      puts "[#{index + 1}/#{updates_data.length}] ✓ #{item['name']}"
    else
      results[:failed] << update
      puts "[#{index + 1}/#{updates_data.length}] ✗ Item #{update[:item_id]}"
    end

    sleep(delay) unless index == updates_data.length - 1
  end

  results
end

# Usage: Update items with different statuses
# ⚠️ Replace column IDs with your board's actual column IDs
updates = [
  {
    item_id: 987654321,
    values: { status: { label: "Done" }, text: "Completed" }
  },
  {
    item_id: 987654322,
    values: { status: { label: "Working on it" }, text: "In progress" }
  },
  {
    item_id: 987654323,
    values: { status: { label: "Stuck" }, text: "Blocked by dependencies" }
  }
]

results = bulk_update_different(client, 1234567890, updates)
```

### Handle Partial Failures

Gracefully handle failures during bulk updates:

```ruby
def bulk_update_with_retry(client, board_id, item_ids, column_values,
                           delay: 0.3, max_retries: 2)
  results = { updated: [], failed: [], retried: [] }
  failed_items = []

  # First pass
  item_ids.each_with_index do |item_id, index|
    response = client.column.change_multiple_values(
      args: {
        board_id: board_id,
        item_id: item_id,
        column_values: JSON.generate(column_values)
      }
    )

    if response.success?
      item = response.body.dig("data", "change_multiple_column_values")
      results[:updated] << item
      puts "[#{index + 1}/#{item_ids.length}] ✓ #{item['name']}"
    else
      failed_items << item_id
      puts "[#{index + 1}/#{item_ids.length}] ✗ Failed: #{item_id} (will retry)"
    end

    sleep(delay) unless index == item_ids.length - 1
  end

  # Retry failed items
  retry_count = 0
  while failed_items.any? && retry_count < max_retries
    retry_count += 1
    puts "\nRetry attempt #{retry_count}/#{max_retries}..."

    current_failures = failed_items.dup
    failed_items.clear

    current_failures.each_with_index do |item_id, index|
      response = client.column.change_multiple_values(
        args: {
          board_id: board_id,
          item_id: item_id,
          column_values: JSON.generate(column_values)
        }
      )

      if response.success?
        item = response.body.dig("data", "change_multiple_column_values")
        results[:updated] << item
        results[:retried] << item_id
        puts "[Retry #{index + 1}/#{current_failures.length}] ✓ #{item['name']}"
      else
        failed_items << item_id
        puts "[Retry #{index + 1}/#{current_failures.length}] ✗ #{item_id}"
      end

      sleep(delay * 2) unless index == current_failures.length - 1
    end
  end

  results[:failed] = failed_items
  results
end

# Usage
item_ids = [987654321, 987654322, 987654323, 987654324, 987654325]
values = { status: { label: "Done" } }

results = bulk_update_with_retry(client, 1234567890, item_ids, values)

puts "\n" + "=" * 50
puts "Updated: #{results[:updated].length}"
puts "Retried successfully: #{results[:retried].length}"
puts "Failed after retries: #{results[:failed].length}"
```

## Bulk Delete/Archive

### Archive Multiple Items

Archive items in bulk with confirmation:

```ruby
def bulk_archive_items(client, item_ids, delay: 0.3, confirm: true)
  if confirm
    print "Archive #{item_ids.length} items? (yes/no): "
    return { archived: [], skipped: item_ids } unless gets.chomp.downcase == "yes"
  end

  results = { archived: [], failed: [] }

  puts "Archiving #{item_ids.length} items..."

  item_ids.each_with_index do |item_id, index|
    response = client.item.archive(item_id)

    if response.success?
      archived = response.body.dig("data", "archive_item")
      results[:archived] << archived
      puts "[#{index + 1}/#{item_ids.length}] ✓ Archived: #{archived['id']}"
    else
      results[:failed] << item_id
      puts "[#{index + 1}/#{item_ids.length}] ✗ Failed: #{item_id}"
    end

    sleep(delay) unless index == item_ids.length - 1
  end

  results
end

# Usage
item_ids = [987654321, 987654322, 987654323]
results = bulk_archive_items(client, item_ids)

puts "\nArchived #{results[:archived].length} items"
```

### Delete Multiple Items

Safely delete items with double confirmation:

```ruby
def bulk_delete_items(client, item_ids, delay: 0.3)
  puts "⚠️  WARNING: You are about to DELETE #{item_ids.length} items."
  puts "This action CANNOT be undone!"
  print "\nType 'DELETE' to confirm: "

  return { deleted: [], cancelled: item_ids } unless gets.chomp == "DELETE"

  print "Are you absolutely sure? (yes/no): "
  return { deleted: [], cancelled: item_ids } unless gets.chomp.downcase == "yes"

  results = { deleted: [], failed: [] }

  puts "\nDeleting #{item_ids.length} items..."

  item_ids.each_with_index do |item_id, index|
    response = client.item.delete(item_id)

    if response.success?
      deleted = response.body.dig("data", "delete_item")
      results[:deleted] << deleted
      puts "[#{index + 1}/#{item_ids.length}] ✓ Deleted: #{deleted['id']}"
    else
      results[:failed] << item_id
      puts "[#{index + 1}/#{item_ids.length}] ✗ Failed: #{item_id}"
    end

    sleep(delay) unless index == item_ids.length - 1
  end

  results
end

# Usage - requires explicit confirmation
item_ids = [987654321, 987654322]
results = bulk_delete_items(client, item_ids)
```

### Archive Items by Status

Archive items matching specific criteria:

```ruby
def archive_by_status(client, board_id, status_value, delay: 0.3)
  # Fetch items with the target status
  # ⚠️ Replace 'status' with your actual status column ID
  response = client.item.page_by_column_values(
    board_id: board_id,
    columns: [
      { column_id: "status", column_values: [status_value] }
    ],
    limit: 500
  )

  return { archived: [], failed: [] } unless response.success?

  items_page = response.body.dig("data", "items_page_by_column_values")
  items = items_page["items"]

  puts "Found #{items.length} items with status '#{status_value}'"
  print "Archive all? (yes/no): "

  return { archived: [], skipped: items.length } unless gets.chomp.downcase == "yes"

  results = { archived: [], failed: [] }

  items.each_with_index do |item, index|
    response = client.item.archive(item["id"])

    if response.success?
      results[:archived] << item
      puts "[#{index + 1}/#{items.length}] ✓ Archived: #{item['name']}"
    else
      results[:failed] << item
      puts "[#{index + 1}/#{items.length}] ✗ Failed: #{item['name']}"
    end

    sleep(delay) unless index == items.length - 1
  end

  results
end

# Usage: Archive all completed items
results = archive_by_status(client, 1234567890, "Done")
puts "\nArchived #{results[:archived].length} completed items"
```

## Process Large Datasets

### Paginate Through All Items

Process all items on a board using cursor pagination:

```ruby
def process_all_items(client, board_id, delay: 0.3)
  all_items = []
  cursor = nil
  page = 1

  loop do
    puts "Fetching page #{page}..."

    response = client.board.items_page(
      board_ids: board_id,
      cursor: cursor,
      limit: 100
    )

    break unless response.success?

    board = response.body.dig("data", "boards", 0)
    break unless board

    items_page = board.dig("items_page")
    items = items_page["items"]

    break if items.empty?

    all_items.concat(items)
    puts "  Fetched #{items.length} items (total: #{all_items.length})"

    cursor = items_page["cursor"]
    break if cursor.nil?

    page += 1
    sleep(delay)
  end

  all_items
end

# Usage
all_items = process_all_items(client, 1234567890)
puts "\nTotal items fetched: #{all_items.length}"
```

### Process in Batches

Process large datasets in manageable batches:

```ruby
def process_in_batches(client, board_id, batch_size: 50, delay: 0.5)
  all_items = []
  cursor = nil
  batch_num = 1

  loop do
    response = client.board.items_page(
      board_ids: board_id,
      cursor: cursor,
      limit: batch_size
    )

    break unless response.success?

    board = response.body.dig("data", "boards", 0)
    break unless board

    items_page = board.dig("items_page")
    items = items_page["items"]
    break if items.empty?

    # Process this batch
    puts "\nProcessing batch #{batch_num} (#{items.length} items)..."

    items.each_with_index do |item, index|
      # Your processing logic here
      puts "  [#{index + 1}/#{items.length}] Processing: #{item['name']}"

      # Example: Update each item
      # response = client.column.change_value(...)
    end

    all_items.concat(items)
    cursor = items_page["cursor"]
    break if cursor.nil?

    batch_num += 1
    puts "\nWaiting before next batch..."
    sleep(delay)
  end

  puts "\n" + "=" * 50
  puts "Processed #{all_items.length} items in #{batch_num} batches"

  all_items
end

# Usage
process_in_batches(client, 1234567890, batch_size: 25, delay: 1.0)
```

### Progress Tracking

Track progress for long-running operations:

```ruby
require "benchmark"

def bulk_operation_with_progress(client, board_id, item_ids,
                                  column_values, delay: 0.3)
  results = {
    updated: [],
    failed: [],
    timing: {}
  }

  total = item_ids.length
  start_time = Time.now

  puts "\n" + "=" * 60
  puts "Starting bulk update of #{total} items"
  puts "=" * 60

  item_ids.each_with_index do |item_id, index|
    item_start = Time.now

    response = client.column.change_multiple_values(
      args: {
        board_id: board_id,
        item_id: item_id,
        column_values: JSON.generate(column_values)
      }
    )

    elapsed = Time.now - item_start

    if response.success?
      item = response.body.dig("data", "change_multiple_column_values")
      results[:updated] << item
      status = "✓"
    else
      results[:failed] << item_id
      status = "✗"
    end

    # Calculate progress
    progress = ((index + 1).to_f / total * 100).round(1)
    elapsed_total = Time.now - start_time
    avg_time = elapsed_total / (index + 1)
    remaining = avg_time * (total - index - 1)

    # Progress bar
    bar_length = 30
    filled = (progress / 100 * bar_length).round
    bar = "█" * filled + "░" * (bar_length - filled)

    puts "[#{bar}] #{progress}% #{status} Item #{index + 1}/#{total}"
    puts "   Time: #{elapsed.round(2)}s | Avg: #{avg_time.round(2)}s | " \
         "ETA: #{remaining.round(0)}s"

    sleep(delay) unless index == total - 1
  end

  total_time = Time.now - start_time
  results[:timing] = {
    total: total_time,
    average: total_time / total,
    items_per_second: total / total_time
  }

  puts "\n" + "=" * 60
  puts "COMPLETED"
  puts "=" * 60
  puts "Updated: #{results[:updated].length}"
  puts "Failed: #{results[:failed].length}"
  puts "Total time: #{total_time.round(2)}s"
  puts "Average: #{results[:timing][:average].round(2)}s per item"
  puts "Speed: #{results[:timing][:items_per_second].round(2)} items/second"
  puts "=" * 60

  results
end

# Usage
item_ids = [987654321, 987654322, 987654323, 987654324, 987654325]
values = { status: { label: "Done" } }

results = bulk_operation_with_progress(client, 1234567890, item_ids, values)
```

### Error Recovery

Save progress and resume after failures:

```ruby
require "json"

def bulk_update_with_checkpoint(client, board_id, item_ids,
                                 column_values, checkpoint_file: "checkpoint.json",
                                 delay: 0.3)
  # Load checkpoint if exists
  completed = []
  if File.exist?(checkpoint_file)
    checkpoint = JSON.parse(File.read(checkpoint_file))
    completed = checkpoint["completed"] || []
    puts "Resuming from checkpoint: #{completed.length} items already processed"
  end

  # Filter out already completed items
  remaining = item_ids - completed

  if remaining.empty?
    puts "All items already processed!"
    return { updated: completed, failed: [] }
  end

  puts "Processing #{remaining.length} remaining items..."

  results = { updated: completed.dup, failed: [] }

  remaining.each_with_index do |item_id, index|
    response = client.column.change_multiple_values(
      args: {
        board_id: board_id,
        item_id: item_id,
        column_values: JSON.generate(column_values)
      }
    )

    if response.success?
      results[:updated] << item_id
      puts "[#{index + 1}/#{remaining.length}] ✓ Updated: #{item_id}"

      # Save checkpoint after each success
      File.write(checkpoint_file, JSON.generate({
        completed: results[:updated],
        last_updated: Time.now.to_s
      }))
    else
      results[:failed] << item_id
      puts "[#{index + 1}/#{remaining.length}] ✗ Failed: #{item_id}"
    end

    sleep(delay) unless index == remaining.length - 1
  end

  # Clean up checkpoint file when done
  File.delete(checkpoint_file) if File.exist?(checkpoint_file)

  results
end

# Usage
item_ids = (1..100).map { |i| 987654000 + i }
values = { status: { label: "Processed" } }

results = bulk_update_with_checkpoint(
  client,
  1234567890,
  item_ids,
  values,
  checkpoint_file: "bulk_update_checkpoint.json"
)
```

## Best Practices

### Rate Limiting Strategy

Implement smart rate limiting:

```ruby
class RateLimiter
  def initialize(requests_per_second: 2)
    @delay = 1.0 / requests_per_second
    @last_request = Time.now - @delay
  end

  def throttle
    elapsed = Time.now - @last_request
    if elapsed < @delay
      sleep(@delay - elapsed)
    end
    @last_request = Time.now
  end
end

def bulk_update_with_rate_limit(client, board_id, item_ids, column_values)
  limiter = RateLimiter.new(requests_per_second: 3)
  results = { updated: [], failed: [] }

  item_ids.each_with_index do |item_id, index|
    limiter.throttle

    response = client.column.change_multiple_values(
      args: {
        board_id: board_id,
        item_id: item_id,
        column_values: JSON.generate(column_values)
      }
    )

    if response.success?
      item = response.body.dig("data", "change_multiple_column_values")
      results[:updated] << item
      puts "[#{index + 1}/#{item_ids.length}] ✓ #{item['name']}"
    else
      results[:failed] << item_id
      puts "[#{index + 1}/#{item_ids.length}] ✗ #{item_id}"
    end
  end

  results
end

# Usage
item_ids = [987654321, 987654322, 987654323]
values = { status: { label: "Done" } }

results = bulk_update_with_rate_limit(client, 1234567890, item_ids, values)
```

### Transaction-like Patterns

Implement rollback for failed operations:

```ruby
def bulk_update_with_rollback(client, board_id, item_ids, new_values, delay: 0.3)
  # First, get current values
  puts "Backing up current values..."
  backups = {}

  item_ids.each do |item_id|
    response = client.item.query(
      args: { ids: [item_id] },
      select: ["id", "name", { column_values: ["id", "value"] }]
    )

    if response.success?
      item = response.body.dig("data", "items", 0)
      backups[item_id] = item["column_values"]
    end

    sleep(delay * 0.5)
  end

  # Perform updates
  puts "\nUpdating items..."
  results = { updated: [], failed: [] }

  item_ids.each_with_index do |item_id, index|
    response = client.column.change_multiple_values(
      args: {
        board_id: board_id,
        item_id: item_id,
        column_values: JSON.generate(new_values)
      }
    )

    if response.success?
      results[:updated] << item_id
      puts "[#{index + 1}/#{item_ids.length}] ✓ Updated: #{item_id}"
    else
      results[:failed] << item_id
      puts "[#{index + 1}/#{item_ids.length}] ✗ Failed: #{item_id}"

      # Critical failure - rollback
      if results[:failed].length > item_ids.length * 0.3
        puts "\n⚠️  Too many failures (#{results[:failed].length}). Rolling back..."

        results[:updated].each_with_index do |updated_id, rb_index|
          # Restore original values
          original = backups[updated_id]
          next unless original

          restore_values = {}
          original.each do |col|
            restore_values[col["id"]] = JSON.parse(col["value"]) rescue nil
          end

          client.column.change_multiple_values(
            args: {
              board_id: board_id,
              item_id: updated_id,
              column_values: JSON.generate(restore_values.compact)
            }
          )

          puts "[#{rb_index + 1}/#{results[:updated].length}] ↶ Rolled back: #{updated_id}"
          sleep(delay)
        end

        return { updated: [], failed: item_ids, rolled_back: true }
      end
    end

    sleep(delay) unless index == item_ids.length - 1
  end

  results
end

# Usage
item_ids = [987654321, 987654322, 987654323]
values = { status: { label: "Done" } }

results = bulk_update_with_rollback(client, 1234567890, item_ids, values)
```

### Optimize API Calls

Minimize requests by using change_multiple_values:

```ruby
# ❌ BAD: Multiple API calls per item
def update_item_inefficient(client, board_id, item_id)
  client.column.change_value(
    args: { board_id: board_id, item_id: item_id, column_id: "status", value: '{"label":"Done"}' }
  )

  client.column.change_value(
    args: { board_id: board_id, item_id: item_id, column_id: "date4", value: '{"date":"2024-12-31"}' }
  )

  client.column.change_value(
    args: { board_id: board_id, item_id: item_id, column_id: "text", value: "Completed" }
  )

  # 3 API calls per item!
end

# ✅ GOOD: Single API call per item
def update_item_efficient(client, board_id, item_id)
  values = {
    status: { label: "Done" },
    date4: { date: "2024-12-31" },
    text: "Completed"
  }

  client.column.change_multiple_values(
    args: {
      board_id: board_id,
      item_id: item_id,
      column_values: JSON.generate(values)
    }
  )

  # 1 API call per item - 3x faster!
end
```

### Batch Size Considerations

Choose optimal batch sizes:

```ruby
def adaptive_batch_processing(client, board_id, delay: 0.5)
  batch_sizes = [100, 50, 25]  # Try larger batches first
  cursor = nil
  total_processed = 0

  batch_sizes.each do |batch_size|
    puts "Trying batch size: #{batch_size}"

    begin
      response = client.board.items_page(
        board_ids: board_id,
        cursor: cursor,
        limit: batch_size
      )

      if response.success?
        board = response.body.dig("data", "boards", 0)
        items_page = board.dig("items_page")
        items = items_page["items"]

        puts "✓ Successfully fetched #{items.length} items"
        puts "Using batch size #{batch_size} for remaining pages"

        # Continue with this batch size
        total_processed += items.length
        cursor = items_page["cursor"]

        while cursor
          sleep(delay)

          response = client.board.items_page(
            board_ids: board_id,
            cursor: cursor,
            limit: batch_size
          )

          break unless response.success?

          board = response.body.dig("data", "boards", 0)
          items_page = board.dig("items_page")
          items = items_page["items"]

          break if items.empty?

          total_processed += items.length
          cursor = items_page["cursor"]

          puts "Processed #{total_processed} items so far..."
        end

        break
      end
    rescue => e
      puts "✗ Batch size #{batch_size} failed: #{e.message}"
      next
    end
  end

  puts "\nTotal processed: #{total_processed} items"
end

# Usage
adaptive_batch_processing(client, 1234567890)
```

## Complete Example

Production-ready bulk operation with all best practices:

```ruby
require "monday_ruby"
require "dotenv/load"
require "json"
require "benchmark"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

class BulkProcessor
  attr_reader :client, :results

  def initialize(client, delay: 0.3, max_retries: 2)
    @client = client
    @delay = delay
    @max_retries = max_retries
    @results = {
      successful: [],
      failed: [],
      retried: [],
      total_time: 0
    }
  end

  def bulk_update_items(board_id, updates_data)
    puts "\n" + "=" * 60
    puts "Bulk Update Operation"
    puts "=" * 60
    puts "Items to update: #{updates_data.length}"
    puts "Rate limit delay: #{@delay}s"
    puts "Max retries: #{@max_retries}"
    puts "=" * 60 + "\n"

    start_time = Time.now
    failed_updates = []

    # First pass
    updates_data.each_with_index do |update, index|
      process_update(board_id, update, index, updates_data.length) do |success, data|
        if success
          @results[:successful] << data
        else
          failed_updates << update
        end
      end

      sleep(@delay) unless index == updates_data.length - 1
    end

    # Retry failed updates
    retry_count = 0
    while failed_updates.any? && retry_count < @max_retries
      retry_count += 1
      puts "\n" + "-" * 60
      puts "Retry Attempt #{retry_count}/#{@max_retries}"
      puts "-" * 60

      current_failures = failed_updates.dup
      failed_updates.clear

      current_failures.each_with_index do |update, index|
        process_update(board_id, update, index, current_failures.length, retry: true) do |success, data|
          if success
            @results[:successful] << data
            @results[:retried] << data
          else
            failed_updates << update
          end
        end

        sleep(@delay * 1.5) unless index == current_failures.length - 1
      end
    end

    @results[:failed] = failed_updates
    @results[:total_time] = Time.now - start_time

    print_summary
    @results
  end

  private

  def process_update(board_id, update, index, total, retry: false)
    prefix = retry ? "  [Retry #{index + 1}/#{total}]" : "[#{index + 1}/#{total}]"

    response = @client.column.change_multiple_values(
      args: {
        board_id: board_id,
        item_id: update[:item_id],
        column_values: JSON.generate(update[:values])
      }
    )

    if response.success?
      item = response.body.dig("data", "change_multiple_column_values")
      puts "#{prefix} ✓ Updated: #{item['name']}"
      yield(true, item)
    else
      puts "#{prefix} ✗ Failed: Item #{update[:item_id]}"
      yield(false, update)
    end
  rescue => e
    puts "#{prefix} ✗ Error: #{e.message}"
    yield(false, update)
  end

  def print_summary
    puts "\n" + "=" * 60
    puts "SUMMARY"
    puts "=" * 60
    puts "Successful: #{@results[:successful].length}"
    puts "Retried & succeeded: #{@results[:retried].length}"
    puts "Failed: #{@results[:failed].length}"
    puts "Total time: #{@results[:total_time].round(2)}s"

    if @results[:successful].any?
      avg_time = @results[:total_time] / @results[:successful].length
      puts "Average time per item: #{avg_time.round(2)}s"
    end

    puts "=" * 60 + "\n"
  end
end

# Usage
processor = BulkProcessor.new(client, delay: 0.3, max_retries: 2)

# ⚠️ Replace with your actual board ID, item IDs, and column IDs
updates = [
  {
    item_id: 987654321,
    values: {
      status: { label: "Done" },
      date4: { date: "2024-12-31" },
      text: "Completed successfully"
    }
  },
  {
    item_id: 987654322,
    values: {
      status: { label: "Working on it" },
      date4: { date: "2024-12-15" },
      text: "In progress"
    }
  },
  {
    item_id: 987654323,
    values: {
      status: { label: "Done" },
      date4: { date: "2024-12-20" },
      text: "Review complete"
    }
  }
]

results = processor.bulk_update_items(1234567890, updates)

# Access results
puts "\nSuccessful updates:"
results[:successful].each do |item|
  puts "  • #{item['name']} (ID: #{item['id']})"
end

if results[:failed].any?
  puts "\nFailed updates:"
  results[:failed].each do |update|
    puts "  • Item ID: #{update[:item_id]}"
  end
end
```

## Next Steps

- [Advanced pagination](/guides/advanced/pagination)
- [Error handling patterns](/guides/advanced/errors)
- [Update multiple columns](/guides/columns/update-multiple)
- [Query items efficiently](/guides/items/query)
