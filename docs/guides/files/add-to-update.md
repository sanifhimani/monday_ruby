# Add File (Asset) to Item Update (Comments)

Add a file to an Item Update.

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

// UploadIO is from the multipart-post gem that is included.
response = client.file.add_file_to_update(
  args: {
    update_id: 987654321,
    file: UploadIO.new(
      File.open('./path/to/polarBear.jpg'),
      'image/jpeg',
      'polarBear.jpg'
    )
  }
)

if response.success?
  monday_file_id = response.body.dig("data", "add_file_to_update", "id")
  puts "✓ Added file #{monday_file_id} to Item's Update"
else
  puts "✗ Failed to add file to Item's Update"
end
```

**Output:**
```
✓ Added file 11235683 to Item's Update
```
