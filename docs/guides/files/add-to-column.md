# Add File (Asset) to File Column

Add a file to a File Column.

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

// UploadIO is from the multipart-post gem that is included.
response = client.file.add_file_to_column(
  args: {
    item_id: 123456789,
    column_id: 'file_123xyz',
    file: UploadIO.new(
      File.open('./path/to/polarBear.jpg'),
      'image/jpeg',
      'polarBear.jpg'
    )
  }
)

if response.success?
  monday_file_id = response.body.dig("data", "add_file_to_column", "id")
  puts "✓ Added file #{monday_file_id} to column"
else
  puts "✗ Failed to add file to column"
end
```

**Output:**
```
✓ Added file 11235683 to column
```


