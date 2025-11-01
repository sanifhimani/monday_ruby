# Archive & Delete Items

Remove items from boards using archive (recoverable) or delete (permanent).

## Archive an Item

Archive items to hide them while keeping them recoverable:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.item.archive(987654321)

if response.success?
  item = response.body.dig("data", "archive_item")
  puts "✓ Archived item ID: #{item['id']}"
else
  puts "✗ Failed to archive item"
end
```

**Output:**
```
✓ Archived item ID: 987654321
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Archive vs Delete</span>
Archived items can be restored from the monday.com UI. Deleted items cannot be recovered.
:::

## Archive with Details

Get more information about the archived item:

```ruby
response = client.item.archive(
  987654321,
  select: ["id", "name", "state", "created_at"]
)

if response.success?
  item = response.body.dig("data", "archive_item")

  puts "Archived Item:"
  puts "  ID: #{item['id']}"
  puts "  Name: #{item['name']}"
  puts "  State: #{item['state']}"
  puts "  Created: #{item['created_at']}"
end
```

## Delete an Item

Permanently delete items:

```ruby
response = client.item.delete(987654321)

if response.success?
  item = response.body.dig("data", "delete_item")
  puts "✓ Deleted item ID: #{item['id']}"
else
  puts "✗ Failed to delete item"
end
```

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Permanent Deletion</span>
Deleted items cannot be recovered. Consider archiving instead if you might need the data later.
:::

## Bulk Archive Items

Archive multiple items:

```ruby
def archive_items_bulk(client, item_ids)
  archived_items = []

  item_ids.each do |item_id|
    response = client.item.archive(item_id)

    if response.success?
      item = response.body.dig("data", "archive_item")
      archived_items << item
      puts "✓ Archived: #{item['id']}"
    else
      puts "✗ Failed to archive: #{item_id}"
    end

    # Rate limiting: pause between requests
    sleep(0.3)
  end

  archived_items
end

# Usage
item_ids = [987654321, 987654322, 987654323]
archived = archive_items_bulk(client, item_ids)

puts "\n✓ Archived #{archived.length} items"
```

**Output:**
```
✓ Archived: 987654321
✓ Archived: 987654322
✓ Archived: 987654323

✓ Archived 3 items
```

## Bulk Delete Items

Delete multiple items permanently:

```ruby
def delete_items_bulk(client, item_ids)
  deleted_items = []

  item_ids.each do |item_id|
    response = client.item.delete(item_id)

    if response.success?
      item = response.body.dig("data", "delete_item")
      deleted_items << item
      puts "✓ Deleted: #{item['id']}"
    else
      puts "✗ Failed to delete: #{item_id}"
    end

    # Rate limiting: pause between requests
    sleep(0.3)
  end

  deleted_items
end

# Usage
item_ids = [987654321, 987654322, 987654323]
deleted = delete_items_bulk(client, item_ids)

puts "\n✓ Deleted #{deleted.length} items"
```

## Archive Items by Status

Archive all items with a specific status:

```ruby
def archive_items_by_status(client, board_id, status_label)
  # Query items with the status
  response = client.item.page_by_column_values(
    board_id: board_id,
    columns: [
      { column_id: "status", column_values: [status_label] }
    ],
    limit: 100,
    select: ["id", "name"]
  )

  return [] unless response.success?

  items_page = response.body.dig("data", "items_page_by_column_values")
  items = items_page["items"]

  puts "Found #{items.length} items with status '#{status_label}'"

  # Archive each item
  archived = []
  items.each do |item|
    archive_response = client.item.archive(item["id"])

    if archive_response.success?
      archived << item
      puts "  ✓ Archived: #{item['name']}"
    end

    sleep(0.3)
  end

  archived
end

# Usage
archived = archive_items_by_status(client, 1234567890, "Done")
puts "\n✓ Archived #{archived.length} completed items"
```

## Delete Old Items

Remove items older than a specific date:

```ruby
require "date"

def delete_items_older_than(client, board_id, days_old)
  cutoff_date = (Date.today - days_old).to_time.utc.iso8601

  # Query all items
  response = client.board.items_page(
    board_ids: board_id,
    limit: 500,
    select: ["id", "name", "created_at"]
  )

  return [] unless response.success?

  items_page = response.body.dig("data", "boards", 0, "items_page")
  items = items_page["items"]

  # Filter items older than cutoff
  old_items = items.select do |item|
    created_at = DateTime.parse(item["created_at"])
    created_at < DateTime.parse(cutoff_date)
  end

  puts "Found #{old_items.length} items older than #{days_old} days"

  # Delete each old item
  deleted = []
  old_items.each do |item|
    delete_response = client.item.delete(item["id"])

    if delete_response.success?
      deleted << item
      puts "  ✓ Deleted: #{item['name']} (#{item['created_at']})"
    end

    sleep(0.3)
  end

  deleted
end

# Usage: Delete items older than 90 days
deleted = delete_items_older_than(client, 1234567890, 90)
puts "\n✓ Deleted #{deleted.length} old items"
```

## Conditional Archive

Archive only if certain conditions are met:

```ruby
def archive_if_complete(client, item_id)
  # Get item details
  response = client.item.query(
    args: { ids: [item_id] },
    select: [
      "id",
      "name",
      {
        column_values: ["id", "text"]
      }
    ]
  )

  return false unless response.success?

  item = response.body.dig("data", "items", 0)
  status = item["column_values"].find { |cv| cv["id"] == "status" }

  # Check if status is "Done"
  return false unless status&.dig("text") == "Done"

  # Archive the item
  archive_response = client.item.archive(item_id)

  if archive_response.success?
    puts "✓ Archived completed item: #{item['name']}"
    true
  else
    false
  end
end

# Usage
archived = archive_if_complete(client, 987654321)
puts archived ? "Item archived" : "Item not complete or archive failed"
```

## Archive with Confirmation

Prompt for confirmation before archiving:

```ruby
def archive_with_confirmation(client, item_id)
  # Get item details first
  response = client.item.query(
    args: { ids: [item_id] },
    select: ["id", "name", "created_at"]
  )

  return unless response.success?

  item = response.body.dig("data", "items", 0)

  puts "\nItem to archive:"
  puts "  Name: #{item['name']}"
  puts "  ID: #{item['id']}"
  puts "  Created: #{item['created_at']}"

  print "\nArchive this item? (y/n): "
  confirmation = gets.chomp.downcase

  return unless confirmation == "y"

  archive_response = client.item.archive(item_id)

  if archive_response.success?
    puts "✓ Item archived successfully"
  else
    puts "✗ Failed to archive item"
  end
end

# Usage
archive_with_confirmation(client, 987654321)
```

## Error Handling

Handle common archive/delete errors:

```ruby
def archive_item_safe(client, item_id)
  response = client.item.archive(item_id)

  if response.success?
    item = response.body.dig("data", "archive_item")
    puts "✓ Archived item ID: #{item['id']}"
    true
  else
    puts "✗ Failed to archive item"
    puts "  Status: #{response.status}"

    if response.body["errors"]
      response.body["errors"].each do |error|
        puts "  Error: #{error['message']}"
      end
    end

    false
  end
rescue Monday::AuthorizationError
  puts "✗ Invalid API token"
  false
rescue Monday::InvalidRequestError => e
  puts "✗ Invalid item ID: #{e.message}"
  false
rescue Monday::Error => e
  puts "✗ API error: #{e.message}"
  false
end

# Usage
success = archive_item_safe(client, 987654321)
```

## Duplicate Before Delete

Create a backup before permanent deletion:

```ruby
def duplicate_and_delete(client, board_id, item_id)
  # Duplicate the item first
  duplicate_response = client.item.duplicate(
    board_id,
    item_id,
    true  # Include updates
  )

  unless duplicate_response.success?
    puts "✗ Failed to duplicate item"
    return false
  end

  duplicated = duplicate_response.body.dig("data", "duplicate_item")
  puts "✓ Created backup copy: #{duplicated['id']}"

  # Now safe to delete original
  delete_response = client.item.delete(item_id)

  if delete_response.success?
    puts "✓ Original item deleted"
    true
  else
    puts "✗ Failed to delete original item"
    false
  end
end

# Usage
success = duplicate_and_delete(client, 1234567890, 987654321)
```

## Complete Example

Archive or delete with full error handling and logging:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

def cleanup_items(client, board_id, status_to_archive, status_to_delete)
  results = {
    archived: [],
    deleted: [],
    errors: []
  }

  # Get items to clean up
  response = client.item.page_by_column_values(
    board_id: board_id,
    columns: [
      { column_id: "status", column_values: status_to_archive + status_to_delete }
    ],
    limit: 100,
    select: [
      "id",
      "name",
      {
        column_values: ["id", "text"]
      }
    ]
  )

  unless response.success?
    puts "✗ Failed to query items"
    return results
  end

  items_page = response.body.dig("data", "items_page_by_column_values")
  items = items_page["items"]

  puts "Found #{items.length} items to process"

  items.each do |item|
    status = item["column_values"].find { |cv| cv["id"] == "status" }
    status_label = status&.dig("text")

    if status_to_archive.include?(status_label)
      # Archive this item
      archive_response = client.item.archive(item["id"])

      if archive_response.success?
        results[:archived] << item
        puts "  ✓ Archived: #{item['name']}"
      else
        results[:errors] << { item: item, action: "archive" }
        puts "  ✗ Failed to archive: #{item['name']}"
      end

    elsif status_to_delete.include?(status_label)
      # Delete this item
      delete_response = client.item.delete(item["id"])

      if delete_response.success?
        results[:deleted] << item
        puts "  ✓ Deleted: #{item['name']}"
      else
        results[:errors] << { item: item, action: "delete" }
        puts "  ✗ Failed to delete: #{item['name']}"
      end
    end

    sleep(0.3)
  end

  results
end

# Usage: Archive "Done" items, Delete "Cancelled" items
results = cleanup_items(
  client,
  1234567890,
  ["Done"],
  ["Cancelled", "Rejected"]
)

puts "\n" + "=" * 50
puts "Cleanup Summary:"
puts "  Archived: #{results[:archived].length} items"
puts "  Deleted: #{results[:deleted].length} items"
puts "  Errors: #{results[:errors].length}"
puts "=" * 50
```

## Undo Delete (Not Supported)

::: danger <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>No Undo for Delete</span>
monday.com does not provide an API to restore deleted items. Always use archive instead of delete unless you're certain the data won't be needed.
:::

## Next Steps

- [Create items](/guides/items/create)
- [Query items](/guides/items/query)
- [Duplicate items for backup](#duplicate-before-delete)
- [Archive boards](/guides/boards/delete)
- [Error handling patterns](/guides/advanced/errors)
