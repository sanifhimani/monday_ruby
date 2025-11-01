# Update Items

Modify item properties and column values in your boards.

## Finding Column IDs

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Column IDs are Board-Specific</span>
**Before updating column values, you must find your board's actual column IDs.** Column IDs like `status`, `text`, or `date` in these examples are placeholders - replace them with your board's real column IDs.
:::

Query your board to get column IDs:

```ruby
response = client.board.query(
  args: { ids: [1234567890] },  # Replace with your board ID
  select: [
    "id",
    "name",
    {
      columns: ["id", "title", "type"]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "boards", 0)

  puts "Columns for board '#{board['name']}':"
  board["columns"].each do |column|
    puts "  • #{column['title']}: '#{column['id']}' (#{column['type']})"
  end
end
```

**Example output:**
```
Columns for board 'Marketing Campaigns':
  • Name: 'name' (name)
  • Status: 'status' (color)
  • Owner: 'people' (people)
  • Due Date: 'date4' (date)
  • Priority: 'status_1' (color)
  • Text: 'text' (text)
```

Use these exact column IDs (e.g., `date4`, `status_1`) in your update calls, not the column titles.

## Update Single Column Value

Update one column value at a time:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# ⚠️ Replace 'status' with your actual column ID from the query above
response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "status",  # Your status column ID (e.g., 'status', 'status_1', etc.)
    value: JSON.generate({ label: "Done" })
  }
)

if response.success?
  item = response.body.dig("data", "change_column_value")
  puts "✓ Updated: #{item['name']}"
else
  puts "✗ Failed to update item"
end
```

**Output:**
```
✓ Updated: Marketing Campaign
```

## Update Simple Column Values

For simple column types, use `change_simple_value`:

### Text Column

```ruby
# ⚠️ Replace 'text' with your actual text column ID
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
  puts "Updated: #{item['name']}"
end
```

### Number Column

```ruby
response = client.column.change_simple_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "numbers",
    value: "42"
  }
)
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Simple vs Complex</span>
Use `change_simple_value` for text, numbers, and simple types. Use `change_value` for status, people, date, and other complex column types.
:::

## Update Multiple Columns

Update several column values at once:

```ruby
require "json"

# ⚠️ Replace all column IDs with your board's actual column IDs
column_values = {
  status: { label: "Working on it" },  # Your status column ID
  text: "High Priority",  # Your text column ID
  numbers: 85  # Your numbers column ID
}

response = client.column.change_multiple_values(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_values: JSON.generate(column_values)
  }
)

if response.success?
  item = response.body.dig("data", "change_multiple_column_values")
  puts "✓ Updated multiple columns for: #{item['name']}"
end
```

## Update Status Column

Change item status:

```ruby
response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "status",
    value: JSON.generate({ label: "Done" })
  }
)

if response.success?
  puts "✓ Status updated to 'Done'"
end
```

### Using Status Index

If you know the status label index:

```ruby
value = JSON.generate({ index: 1 })

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "status",
    value: value
  }
)
```

## Update Date Column

Set dates with or without time:

### Date Only

```ruby
value = JSON.generate({ date: "2024-12-31" })

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "date",
    value: value
  }
)
```

### Date and Time

```ruby
value = JSON.generate({
  date: "2024-12-31",
  time: "14:30:00"
})

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "date",
    value: value
  }
)
```

### Clear Date

```ruby
value = JSON.generate({ date: nil, time: nil })

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "date",
    value: value
  }
)
```

## Update People Column

Assign people to an item:

### Single Person

```ruby
value = JSON.generate({
  personsAndTeams: [
    { id: 12345678, kind: "person" }
  ]
})

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "people",
    value: value
  }
)
```

### Multiple People

```ruby
value = JSON.generate({
  personsAndTeams: [
    { id: 12345678, kind: "person" },
    { id: 87654321, kind: "person" }
  ]
})

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "people",
    value: value
  }
)
```

### Include Teams

```ruby
value = JSON.generate({
  personsAndTeams: [
    { id: 12345678, kind: "person" },
    { id: 99999999, kind: "team" }
  ]
})

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "people",
    value: value
  }
)
```

## Update Timeline Column

Set timeline start and end dates:

```ruby
value = JSON.generate({
  from: "2024-01-01",
  to: "2024-03-31"
})

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "timeline",
    value: value
  }
)
```

## Update Dropdown Column

Set dropdown selection:

```ruby
value = JSON.generate({ labels: [123] })  # Label ID

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "dropdown",
    value: value
  }
)
```

## Update Link Column

Add URL links:

```ruby
value = JSON.generate({
  url: "https://example.com",
  text: "Example Website"
})

response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "link",
    value: value
  }
)
```

## Bulk Update Items

Update multiple items efficiently:

```ruby
def bulk_update_status(client, board_id, item_ids, status_label)
  updated_items = []

  item_ids.each do |item_id|
    response = client.column.change_value(
      args: {
        board_id: board_id,
        item_id: item_id,
        column_id: "status",
        value: JSON.generate({ label: status_label })
      }
    )

    if response.success?
      item = response.body.dig("data", "change_column_value")
      updated_items << item
      puts "✓ Updated: #{item['name']}"
    else
      puts "✗ Failed to update item #{item_id}"
    end

    # Rate limiting: pause between requests
    sleep(0.3)
  end

  updated_items
end

# Usage
item_ids = [987654321, 987654322, 987654323]
items = bulk_update_status(client, 1234567890, item_ids, "Done")

puts "\n✓ Updated #{items.length} items"
```

## Update with Create or Get

Update existing or create new column value:

```ruby
response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "status",
    value: JSON.generate({ label: "Custom Status" }),
    create_labels_if_missing: true
  }
)

if response.success?
  puts "✓ Status updated (label created if needed)"
end
```

## Customize Response Fields

Get detailed information about the updated item:

```ruby
response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "status",
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

## Clear Column Value

Remove a column's value:

```ruby
response = client.column.change_value(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_id: "status",
    value: JSON.generate({})
  }
)

if response.success?
  puts "✓ Column value cleared"
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
  "status",
  value
)
```

## Complete Example

Update multiple columns with full error handling:

```ruby
require "monday_ruby"
require "dotenv/load"
require "json"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# IMPORTANT: First, get your board's column IDs:
# See "Finding Column IDs" section at the top of this guide

# Update multiple columns at once
# ⚠️ Replace all column IDs with your board's actual column IDs
column_values = {
  status: { label: "Working on it" },  # Your status column ID
  text: "Updated task description",  # Your text column ID
  date4: { date: "2024-12-31", time: "17:00:00" },  # Your date column ID
  people: {  # Your people column ID
    personsAndTeams: [
      { id: 12345678, kind: "person" }  # Replace with actual user ID
    ]
  }
}

response = client.column.change_multiple_values(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_values: JSON.generate(column_values)
  },
  select: [
    "id",
    "name",
    "state",
    {
      column_values: ["id", "text", "type", "value"]
    }
  ]
)

if response.success?
  item = response.body.dig("data", "change_multiple_column_values")

  puts "\n✓ Item Updated Successfully\n"
  puts "#{'=' * 50}"
  puts "Name: #{item['name']}"
  puts "ID: #{item['id']}"
  puts "State: #{item['state']}"

  puts "\nUpdated Column Values:"
  item["column_values"].each do |col_val|
    next if col_val["text"].nil? || col_val["text"].empty?
    puts "  • #{col_val['id']}: #{col_val['text']} (#{col_val['type']})"
  end

  puts "#{'=' * 50}"
else
  puts "\n✗ Failed to update item"
  puts "Status code: #{response.status}"

  if response.body["error_message"]
    puts "Error: #{response.body['error_message']}"
  end
end
```

## Update Based on Current Value

Read current value before updating:

```ruby
# First, get the current item
query_response = client.item.query(
  args: { ids: [987654321] },
  select: [
    "id",
    "name",
    {
      column_values: ["id", "text", "value"]
    }
  ]
)

if query_response.success?
  item = query_response.body.dig("data", "items", 0)
  current_status = item["column_values"].find { |cv| cv["id"] == "status" }

  # Update based on current value
  new_status = if current_status&.dig("text") == "Working on it"
                 "Done"
               else
                 "Working on it"
               end

  # Update the status
  update_response = client.column.change_value(
    args: {
      board_id: 1234567890,
      item_id: 987654321,
      column_id: "status",
      value: JSON.generate({ label: new_status })
    }
  )

  if update_response.success?
    puts "✓ Status toggled to: #{new_status}"
  end
end
```

## Conditional Updates

Update only if condition is met:

```ruby
def update_if_status(client, board_id, item_id, current_status, new_column_values)
  # Query current item
  response = client.item.query(
    args: { ids: [item_id] },
    select: [
      "id",
      {
        column_values: ["id", "text"]
      }
    ]
  )

  return false unless response.success?

  item = response.body.dig("data", "items", 0)
  status = item["column_values"].find { |cv| cv["id"] == "status" }

  # Check condition
  return false unless status&.dig("text") == current_status

  # Perform update
  update_response = client.column.change_multiple_values(
    args: {
      board_id: board_id,
      item_id: item_id,
      column_values: JSON.generate(new_column_values)
    }
  )

  update_response.success?
end

# Usage
updated = update_if_status(
  client,
  1234567890,
  987654321,
  "Working on it",
  { status: { label: "Done" }, text: "Completed successfully" }
)

puts updated ? "✓ Updated" : "✗ Condition not met"
```

## Next Steps

- [Query items](/guides/items/query)
- [Create items](/guides/items/create)
- [Update column metadata](/guides/columns/metadata)
- [Batch operations](/guides/advanced/batch)
- [Work with subitems](/guides/items/subitems)
