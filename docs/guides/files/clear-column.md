# Clear column files

Clears all files in an item's File column. This is a helper method for files and you could also use the column.change_value to clear the column as well.

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

// UploadIO is from the multipart-post gem that is included.
response = client.file.clear_file_column(
  args: {
    board_id: 123456789,
    item_id: 789654321,
    column_id: 'file_123xyz'
  }
)

if response.success?
  puts "✓ Column files cleared"
else
  puts "✗ Failed to add file to Item's Update"
end
```

**Output:**
```
✓ Column files cleared
```
