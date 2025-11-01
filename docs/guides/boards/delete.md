# Archive & Delete Boards

Archive or permanently delete boards from your monday.com account.

## Archive a Board

Archiving removes a board from active view while preserving data:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

board_id = 1234567890

response = client.board.archive(board_id)

if response.success?
  archived_board = response.body.dig("data", "archive_board")
  puts "✓ Archived board ID: #{archived_board['id']}"
else
  puts "✗ Failed to archive board"
end
```

## Archive with Custom Fields

Return specific fields from the archived board:

```ruby
response = client.board.archive(
  board_id,
  select: ["id", "name", "state"]
)

if response.success?
  board = response.body.dig("data", "archive_board")

  puts "✓ Archived: #{board['name']}"
  puts "  ID: #{board['id']}"
  puts "  State: #{board['state']}"
end
```

## Delete a Board

Permanently delete a board:

```ruby
board_id = 1234567890

response = client.board.delete(board_id)

if response.success?
  deleted_board = response.body.dig("data", "delete_board")
  puts "✓ Deleted board ID: #{deleted_board['id']}"
else
  puts "✗ Failed to delete board"
end
```

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Permanent Deletion</span>
Deleting a board is permanent and cannot be undone. All items, updates, and files will be lost. Consider archiving instead.
:::

## Delete with Custom Fields

Return specific fields from the deleted board:

```ruby
response = client.board.delete(
  board_id,
  select: ["id", "name"]
)

if response.success?
  board = response.body.dig("data", "delete_board")
  puts "✓ Deleted: #{board['name']} (ID: #{board['id']})"
end
```

## Archive vs Delete

| Operation | Recoverable | Data Preserved | Use Case |
|-----------|-------------|----------------|----------|
| Archive | Yes | Yes | Temporarily hide completed projects |
| Delete | No | No | Permanently remove unwanted boards |

## Confirm Before Delete

Require user confirmation:

```ruby
def confirm_delete(board_name)
  puts "⚠️  You are about to permanently delete '#{board_name}'"
  print "Type 'DELETE' to confirm: "
  input = gets.chomp

  input == "DELETE"
end

board_id = 1234567890

# Get board name first
query_response = client.board.query(
  args: { ids: [board_id] },
  select: ["id", "name"]
)

if query_response.success?
  board = query_response.body.dig("data", "boards", 0)

  if confirm_delete(board['name'])
    delete_response = client.board.delete(board_id)

    if delete_response.success?
      puts "✓ Board deleted"
    else
      puts "✗ Delete failed"
    end
  else
    puts "❌ Delete cancelled"
  end
end
```

## Safe Archive Function

Archive with error handling:

```ruby
def safe_archive(client, board_id)
  response = client.board.archive(board_id)

  if response.success?
    board = response.body.dig("data", "archive_board")
    puts "✓ Archived board: #{board['id']}"
    true
  else
    puts "✗ Archive failed"
    puts "  Status: #{response.status}"

    if response.body["error_message"]
      puts "  Error: #{response.body['error_message']}"
    end

    false
  end
rescue Monday::AuthorizationError
  puts "✗ Board not found or no permission"
  false
rescue Monday::Error => e
  puts "✗ API error: #{e.message}"
  false
end

# Usage
safe_archive(client, 1234567890)
```

## Safe Delete Function

Delete with comprehensive error handling:

```ruby
def safe_delete(client, board_id)
  response = client.board.delete(board_id)

  if response.success?
    board = response.body.dig("data", "delete_board")
    puts "✓ Deleted board: #{board['id']}"
    true
  else
    puts "✗ Delete failed"
    puts "  Status: #{response.status}"
    false
  end
rescue Monday::InvalidRequestError => e
  if e.message.include?("InvalidBoardIdException")
    puts "✗ Board does not exist"
  else
    puts "✗ Invalid request: #{e.message}"
  end
  false
rescue Monday::AuthorizationError
  puts "✗ No permission to delete this board"
  false
rescue Monday::Error => e
  puts "✗ API error: #{e.message}"
  false
end

# Usage
safe_delete(client, 1234567890)
```

## Bulk Archive

Archive multiple boards:

```ruby
def bulk_archive(client, board_ids)
  results = { success: [], failed: [] }

  board_ids.each do |board_id|
    response = client.board.archive(board_id)

    if response.success?
      results[:success] << board_id
      puts "✓ Archived: #{board_id}"
    else
      results[:failed] << board_id
      puts "✗ Failed: #{board_id}"
    end
  end

  puts "\nResults:"
  puts "  Archived: #{results[:success].length}"
  puts "  Failed: #{results[:failed].length}"

  results
end

# Usage
board_ids = [1234567890, 2345678901, 3456789012]
bulk_archive(client, board_ids)
```

**Example output:**
```
✓ Archived: 1234567890
✓ Archived: 2345678901
✗ Failed: 3456789012

Results:
  Archived: 2
  Failed: 1
```

## Archive Old Boards

Archive boards based on criteria:

```ruby
def archive_old_boards(client, days_threshold: 90)
  # Query all boards
  response = client.board.query(
    select: ["id", "name", "updated_at"]
  )

  return unless response.success?

  boards = response.body.dig("data", "boards")
  archived_count = 0

  boards.each do |board|
    # Skip if no updated_at or updated recently
    next unless board["updated_at"]

    updated_date = Time.parse(board["updated_at"])
    days_old = (Time.now - updated_date) / 86400

    if days_old > days_threshold
      archive_response = client.board.archive(board["id"])

      if archive_response.success?
        puts "✓ Archived: #{board['name']} (#{days_old.to_i} days old)"
        archived_count += 1
      else
        puts "✗ Failed to archive: #{board['name']}"
      end
    end
  end

  puts "\n#{archived_count} boards archived"
end

# Archive boards not updated in 90 days
archive_old_boards(client, days_threshold: 90)
```

## Restore Archived Board

Query and restore from archive:

```ruby
# First, find archived boards
response = client.board.query(
  args: { state: :archived },
  select: ["id", "name"]
)

if response.success?
  archived_boards = response.body.dig("data", "boards")

  puts "Archived boards:"
  archived_boards.each do |board|
    puts "  #{board['id']}: #{board['name']}"
  end

  # To restore, update the board state via monday.com UI
  # API doesn't support programmatic restoration
  puts "\nNote: Restore boards via monday.com web interface"
end
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Restoring Boards</span>
Archived boards can be restored through the monday.com web interface. The API currently doesn't support programmatic restoration.
:::

## Complete Example

Safe board deletion with confirmation:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

board_id = 1234567890

# Step 1: Get board details
query_response = client.board.query(
  args: { ids: [board_id] },
  select: ["id", "name", "description", { items: ["id"] }]
)

unless query_response.success?
  puts "❌ Board not found"
  exit
end

board = query_response.body.dig("data", "boards", 0)

# Step 2: Show board info
puts "\n📋 Board Information"
puts "=" * 50
puts "Name: #{board['name']}"
puts "ID: #{board['id']}"
puts "Items: #{board['items'].length}"
puts "Description: #{board['description']}" if board['description']
puts "=" * 50

# Step 3: Choose action
puts "\nWhat would you like to do?"
puts "1. Archive (reversible)"
puts "2. Delete (permanent)"
puts "3. Cancel"
print "\nChoice: "

choice = gets.chomp.to_i

case choice
when 1
  # Archive
  response = client.board.archive(board_id)

  if response.success?
    puts "\n✓ Board archived successfully"
    puts "  You can restore it from the Archive in monday.com"
  else
    puts "\n✗ Archive failed"
  end

when 2
  # Delete
  puts "\n⚠️  WARNING: This will permanently delete '#{board['name']}'"
  puts "This action cannot be undone!"
  print "Type 'DELETE' to confirm: "

  if gets.chomp == "DELETE"
    response = client.board.delete(board_id)

    if response.success?
      puts "\n✓ Board permanently deleted"
    else
      puts "\n✗ Delete failed"
    end
  else
    puts "\n❌ Delete cancelled"
  end

when 3
  puts "\n❌ Operation cancelled"

else
  puts "\n❌ Invalid choice"
end
```

## Next Steps

- [Create new boards](/guides/boards/create)
- [Duplicate boards](/guides/boards/duplicate)
- [Query archived boards](/guides/boards/query)
- [Understand error handling](/guides/advanced/errors)
