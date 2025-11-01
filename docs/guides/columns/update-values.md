# Update Column Values

Set and update column values for items on your boards.

## Finding Column IDs

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Column IDs are Board-Specific</span>
**Before updating column values, you must find your board's actual column IDs.** See the [Items Create guide](/guides/items/create#finding-column-ids) for how to query column IDs.
:::

## Update Simple Column Value

For simple column types (text, numbers), use `change_simple_value`:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# ⚠️ Replace with your actual column ID
response = client.column.change_simple_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "text",  # Your text column ID
    value: "Updated text content"
  }
)

if response.success?
  item = response.body.dig("data", "change_simple_column_value")
  puts "✓ Updated: #{item['name']}"
else
  puts "✗ Failed to update column"
end
```

**Output:**
```
✓ Updated: Marketing Campaign
```

## Update Complex Column Value

For complex types (status, people, date), use `change_value` with JSON:

```ruby
require "json"

# ⚠️ Replace with your actual column ID
response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "status",  # Your status column ID
    value: JSON.generate({ label: "Done" })
  }
)

if response.success?
  item = response.body.dig("data", "change_column_value")
  puts "✓ Status updated for: #{item['name']}"
end
```

## Update Different Column Types

### Text Column

```ruby
response = client.column.change_simple_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "text",  # ⚠️ Your text column ID
    value: "Project description here"
  }
)
```

### Numbers Column

```ruby
response = client.column.change_simple_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "numbers",  # ⚠️ Your numbers column ID
    value: "12500"  # Pass as string
  }
)
```

### Status Column

```ruby
value = JSON.generate({ label: "Working on it" })

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "status",  # ⚠️ Your status column ID
    value: value
  }
)
```

### Date Column

```ruby
# Date only
value = JSON.generate({ date: "2024-12-31" })

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "date4",  # ⚠️ Your date column ID
    value: value
  }
)

# Date with time
value = JSON.generate({
  date: "2024-12-31",
  time: "14:30:00"
})

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "date4",
    value: value
  }
)
```

### People Column

```ruby
# Single person
value = JSON.generate({
  personsAndTeams: [
    { id: 12345678, kind: "person" }  # Replace with actual user ID
  ]
})

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "people",  # ⚠️ Your people column ID
    value: value
  }
)

# Multiple people
value = JSON.generate({
  personsAndTeams: [
    { id: 12345678, kind: "person" },
    { id: 87654321, kind: "person" }
  ]
})
```

### Timeline Column

```ruby
value = JSON.generate({
  from: "2024-01-01",
  to: "2024-03-31"
})

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "timeline",  # ⚠️ Your timeline column ID
    value: value
  }
)
```

### Dropdown Column

```ruby
value = JSON.generate({ labels: [123] })  # Label ID from column settings

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "dropdown",  # ⚠️ Your dropdown column ID
    value: value
  }
)
```

### Link Column

```ruby
value = JSON.generate({
  url: "https://example.com",
  text: "Example Website"
})

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "link",  # ⚠️ Your link column ID
    value: value
  }
)
```

### Email Column

```ruby
value = JSON.generate({
  email: "user@example.com",
  text: "Contact Email"
})

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "email",  # ⚠️ Your email column ID
    value: value
  }
)
```

### Phone Column

```ruby
value = JSON.generate({
  phone: "+1-555-123-4567",
  countryShortName: "US"
})

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "phone",  # ⚠️ Your phone column ID
    value: value
  }
)
```

### Checkbox Column

```ruby
value = JSON.generate({ checked: "true" })

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "checkbox",  # ⚠️ Your checkbox column ID
    value: value
  }
)
```

## Clear Column Value

Remove a column's value:

```ruby
response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "status",  # ⚠️ Your column ID
    value: JSON.generate({})
  }
)

if response.success?
  puts "✓ Column value cleared"
end
```

## Bulk Update Same Column

Update the same column for multiple items:

```ruby
def bulk_update_status(client, board_id, item_ids, status_label, column_id)
  updated_count = 0

  item_ids.each do |item_id|
    response = client.column.change_value(
      args: {
        board_id: board_id,
        item_id: item_id,
        column_id: column_id,
        value: JSON.generate({ label: status_label })
      }
    )

    if response.success?
      updated_count += 1
      puts "✓ Updated item #{item_id}"
    else
      puts "✗ Failed to update item #{item_id}"
    end

    sleep(0.3)  # Rate limiting
  end

  updated_count
end

# Usage
item_ids = [987654321, 987654322, 987654323]
count = bulk_update_status(
  client,
  1234567890,
  item_ids,
  "Done",
  "status"  # ⚠️ Replace with your status column ID
)

puts "\n✓ Updated #{count} items"
```

## Get Updated Item Details

Retrieve updated item information:

```ruby
response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "status",  # ⚠️ Your column ID
    value: JSON.generate({ label: "Done" })
  },
  select: [
    "id",
    "name",
    "state",
    {
      column_values: ["id", "text", "type"]
    }
  ]
)

if response.success?
  item = response.body.dig("data", "change_column_value")

  puts "Updated: #{item['name']}"
  puts "Column Values:"

  item["column_values"].each do |col_val|
    next if col_val["text"].nil? || col_val["text"].empty?
    puts "  • #{col_val['id']}: #{col_val['text']}"
  end
end
```

## Error Handling

Handle common update errors:

```ruby
def update_column_safe(client, board_id, item_id, column_id, value)
  response = client.column.change_value(
    args: {
      board_id: board_id,
      item_id: item_id,
      column_id: column_id,
      value: value
    }
  )

  if response.success?
    item = response.body.dig("data", "change_column_value")
    puts "✓ Updated: #{item['name']}"
    true
  else
    puts "✗ Failed to update column"
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
  puts "✗ Invalid request: #{e.message}"
  false
rescue Monday::Error => e
  puts "✗ API error: #{e.message}"
  false
end

# Usage
value = JSON.generate({ label: "Done" })
success = update_column_safe(
  client,
  1234567890,
  987654321,
  "status",  # ⚠️ Your column ID
  value
)
```

## Complete Example

Update various column types for an item:

```ruby
require "monday_ruby"
require "dotenv/load"
require "json"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

board_id = 1234567890
item_id = 987654321

# IMPORTANT: Replace all column IDs with your board's actual column IDs

puts "\n📝 Updating Item Columns\n#{'=' * 50}\n"

# Update status
puts "Updating status..."
response = client.column.change_value(
  args: {
    board_id: board_id,
    item_id: item_id,
    column_id: "status",  # ⚠️ Your status column ID
    value: JSON.generate({ label: "Working on it" })
  }
)
puts response.success? ? "✓ Status updated" : "✗ Failed"

# Update due date
puts "Updating due date..."
response = client.column.change_value(
  args: {
    board_id: board_id,
    item_id: item_id,
    column_id: "date4",  # ⚠️ Your date column ID
    value: JSON.generate({ date: "2024-12-31", time: "17:00:00" })
  }
)
puts response.success? ? "✓ Due date updated" : "✗ Failed"

# Update owner
puts "Updating owner..."
response = client.column.change_value(
  args: {
    board_id: board_id,
    item_id: item_id,
    column_id: "people",  # ⚠️ Your people column ID
    value: JSON.generate({
      personsAndTeams: [
        { id: 12345678, kind: "person" }  # ⚠️ Replace with actual user ID
      ]
    })
  }
)
puts response.success? ? "✓ Owner updated" : "✗ Failed"

# Update text note
puts "Updating notes..."
response = client.column.change_simple_value(
  args: {
    board_id: board_id,
    item_id: item_id,
    column_id: "text",  # ⚠️ Your text column ID
    value: "High priority task - needs review"
  }
)
puts response.success? ? "✓ Notes updated" : "✗ Failed"

puts "\n#{'=' * 50}"
puts "✓ Column updates complete"
puts "#{'=' * 50}"
```

## Next Steps

- [Update multiple column values](/guides/columns/update-multiple)
- [Query column values](/guides/columns/query)
- [Create columns](/guides/columns/create)
- [Update items](/guides/items/update)
