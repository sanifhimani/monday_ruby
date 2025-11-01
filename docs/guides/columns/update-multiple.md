# Update Multiple Column Values

Update several column values at once for better performance and efficiency.

## Finding Column IDs

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Column IDs are Board-Specific</span>
**Before updating column values, you must find your board's actual column IDs.** See the [Items Create guide](/guides/items/create#finding-column-ids) for how to query column IDs.
:::

## Basic Multiple Update

Update several columns in a single API call:

```ruby
require "monday_ruby"
require "json"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# ⚠️ Replace all column IDs with your board's actual column IDs
column_values = {
  status: { label: "Working on it" },  # Your status column ID
  text: "High priority task",  # Your text column ID
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
else
  puts "✗ Failed to update columns"
end
```

**Output:**
```
✓ Updated multiple columns for: Marketing Campaign
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Performance Benefit</span>
Updating multiple columns at once is more efficient than making separate API calls for each column. It also ensures atomicity - all updates succeed or fail together.
:::

## Update Mixed Column Types

Combine simple and complex column types:

```ruby
# ⚠️ Replace all column IDs with your board's actual column IDs
column_values = {
  status: {  # Status column
    label: "Done"
  },
  text: "Completed successfully",  # Text column
  date4: {  # Date column
    date: "2024-12-31",
    time: "17:00:00"
  },
  people: {  # People column
    personsAndTeams: [
      { id: 12345678, kind: "person" }  # Replace with actual user ID
    ]
  },
  numbers: 100,  # Numbers column
  checkbox: {  # Checkbox column
    checked: "true"
  }
}

response = client.column.change_multiple_values(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_values: JSON.generate(column_values)
  }
)
```

## Update Item with Full Details

Set all relevant columns when creating or updating an item:

```ruby
def update_task_complete(client, board_id, item_id)
  # ⚠️ Replace all column IDs with your board's actual column IDs
  column_values = {
    status: {
      label: "Done"
    },
    date4: {
      date: Date.today.to_s
    },
    text: "Task completed on time",
    numbers: 100  # 100% complete
  }

  response = client.column.change_multiple_values(
    args: {
      board_id: board_id,
      item_id: item_id,
      column_values: JSON.generate(column_values)
    }
  )

  if response.success?
    item = response.body.dig("data", "change_multiple_column_values")
    puts "✓ Task marked complete: #{item['name']}"
    true
  else
    puts "✗ Failed to update task"
    false
  end
end

# Usage
update_task_complete(client, 1234567890, 987654321)
```

## Bulk Update Multiple Items

Update the same columns for multiple items:

```ruby
def bulk_update_items(client, board_id, item_ids, column_values)
  updated_count = 0

  item_ids.each do |item_id|
    response = client.column.change_multiple_values(
      args: {
        board_id: board_id,
        item_id: item_id,
        column_values: JSON.generate(column_values)
      }
    )

    if response.success?
      item = response.body.dig("data", "change_multiple_column_values")
      updated_count += 1
      puts "✓ Updated: #{item['name']}"
    else
      puts "✗ Failed to update item #{item_id}"
    end

    sleep(0.3)  # Rate limiting
  end

  updated_count
end

# Usage: Mark multiple tasks as complete
# ⚠️ Replace column IDs with your actual column IDs
item_ids = [987654321, 987654322, 987654323]
values = {
  status: { label: "Done" },
  date4: { date: Date.today.to_s },
  text: "Batch completed"
}

count = bulk_update_items(client, 1234567890, item_ids, values)
puts "\n✓ Updated #{count} items"
```

## Update with Conditional Logic

Update columns based on current values or conditions:

```ruby
def update_if_in_progress(client, board_id, item_id)
  # First, get current item
  query_response = client.item.query(
    args: { ids: [item_id] },
    select: [
      "id",
      "name",
      {
        column_values: ["id", "text"]
      }
    ]
  )

  return false unless query_response.success?

  item = query_response.body.dig("data", "items", 0)
  status = item["column_values"].find { |cv| cv["id"] == "status" }

  # Only update if status is "In Progress"
  return false unless status&.dig("text") == "Working on it"

  # Update to next stage
  # ⚠️ Replace column IDs with your actual column IDs
  column_values = {
    status: { label: "Review" },
    text: "Ready for review",
    date4: { date: Date.today.to_s }
  }

  update_response = client.column.change_multiple_values(
    args: {
      board_id: board_id,
      item_id: item_id,
      column_values: JSON.generate(column_values)
    }
  )

  update_response.success?
end

# Usage
if update_if_in_progress(client, 1234567890, 987654321)
  puts "✓ Task moved to review"
else
  puts "Task not in progress or update failed"
end
```

## Get Updated Column Values

Retrieve updated values after the change:

```ruby
response = client.column.change_multiple_values(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_values: JSON.generate({
      status: { label: "Done" },  # ⚠️ Your column IDs
      text: "Completed",
      numbers: 100
    })
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

  puts "Updated: #{item['name']}"
  puts "\nColumn Values:"

  item["column_values"].each do |col_val|
    next if col_val["text"].nil? || col_val["text"].empty?
    puts "  • #{col_val['id']}: #{col_val['text']} (#{col_val['type']})"
  end
end
```

## Error Handling

Handle update errors gracefully:

```ruby
def update_columns_safe(client, board_id, item_id, column_values)
  response = client.column.change_multiple_values(
    args: {
      board_id: board_id,
      item_id: item_id,
      column_values: JSON.generate(column_values)
    }
  )

  if response.success?
    item = response.body.dig("data", "change_multiple_column_values")
    puts "✓ Updated: #{item['name']}"
    true
  else
    puts "✗ Failed to update columns"
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
values = {
  status: { label: "Done" },
  text: "Task complete"
}

success = update_columns_safe(client, 1234567890, 987654321, values)
```

## Clear Multiple Columns

Remove values from several columns at once:

```ruby
# ⚠️ Replace column IDs with your actual column IDs
column_values = {
  status: {},  # Empty object clears the value
  text: "",  # Empty string for text columns
  date4: {},
  people: {}
}

response = client.column.change_multiple_values(
  args: {
    board_id: 1234567890,
    item_id: 987654321,
    column_values: JSON.generate(column_values)
  }
)

if response.success?
  puts "✓ Multiple columns cleared"
end
```

## Complete Example

Update item with full workflow transition:

```ruby
require "monday_ruby"
require "dotenv/load"
require "json"
require "date"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

def transition_to_qa(client, board_id, item_id, assignee_id)
  # IMPORTANT: Replace all column IDs with your board's actual column IDs

  column_values = {
    status: {  # ⚠️ Your status column ID
      label: "QA Testing"
    },
    people: {  # ⚠️ Your people column ID
      personsAndTeams: [
        { id: assignee_id, kind: "person" }
      ]
    },
    date4: {  # ⚠️ Your date column ID
      date: (Date.today + 3).to_s  # Due in 3 days
    },
    text: "Moved to QA for testing",  # ⚠️ Your text column ID
    numbers: 80  # ⚠️ Your numbers column ID (80% complete)
  }

  response = client.column.change_multiple_values(
    args: {
      board_id: board_id,
      item_id: item_id,
      column_values: JSON.generate(column_values)
    },
    select: [
      "id",
      "name",
      {
        column_values: ["id", "text"]
      }
    ]
  )

  if response.success?
    item = response.body.dig("data", "change_multiple_column_values")

    puts "\n✓ Item Transitioned to QA\n#{'=' * 50}"
    puts "Item: #{item['name']}"
    puts "Updated Values:"

    item["column_values"].each do |col|
      next if col["text"].nil? || col["text"].empty?
      puts "  • #{col['id']}: #{col['text']}"
    end

    puts "#{'=' * 50}"
    true
  else
    puts "✗ Failed to transition item"
    false
  end
end

# Usage
success = transition_to_qa(
  client,
  1234567890,  # board_id
  987654321,   # item_id
  12345678     # assignee_id - replace with actual user ID
)
```

**Output:**
```
✓ Item Transitioned to QA
==================================================
Item: Feature Development
Updated Values:
  • status: QA Testing
  • people: John Doe
  • date4: 2024-12-15
  • text: Moved to QA for testing
  • numbers: 80
==================================================
```

## Best Practices

### Do's

- ✅ Update multiple related columns together
- ✅ Use JSON.generate for all column values
- ✅ Include rate limiting delays in loops
- ✅ Verify column IDs before updating
- ✅ Handle errors appropriately

### Don'ts

- ❌ Update columns one-by-one when you can batch them
- ❌ Hardcode column IDs without verification
- ❌ Skip error handling
- ❌ Update too many items without rate limiting
- ❌ Mix up column IDs between boards

## Next Steps

- [Update single column value](/guides/columns/update-values)
- [Query column values](/guides/columns/query)
- [Create columns](/guides/columns/create)
- [Batch operations](/guides/advanced/batch)
