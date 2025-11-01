# Update Board Settings

Modify board properties like name, description, and communication settings.

## Update Board Name

Change a board's display name:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

board_id = 1234567890

response = client.board.update(
  args: {
    board_id: board_id,
    board_attribute: :name,
    new_value: "Updated Board Name"
  }
)

if response.success?
  result = JSON.parse(response.body["data"]["update_board"])

  if result["success"]
    puts "✓ Board name updated successfully"
  else
    puts "✗ Update failed"
  end
end
```

## Update Board Description

Modify the board's description:

```ruby
board_id = 1234567890

response = client.board.update(
  args: {
    board_id: board_id,
    board_attribute: :description,
    new_value: "This board tracks all Q1 2024 marketing campaigns and initiatives"
  }
)

if response.success?
  result = JSON.parse(response.body["data"]["update_board"])

  if result["success"]
    puts "✓ Description updated"
  else
    puts "✗ Update failed"
  end
end
```

## Update Communication Setting

Set the board's communication value (typically a meeting link or ID):

```ruby
board_id = 1234567890

response = client.board.update(
  args: {
    board_id: board_id,
    board_attribute: :communication,
    new_value: "https://zoom.us/j/123456789"
  }
)

if response.success?
  result = JSON.parse(response.body["data"]["update_board"])

  if result["success"]
    puts "✓ Communication setting updated"
  end
end
```

## Response Structure

The update response contains success status and undo data:

```ruby
response = client.board.update(
  args: {
    board_id: 1234567890,
    board_attribute: :name,
    new_value: "New Name"
  }
)

if response.success?
  # Response is JSON string, needs parsing
  result = JSON.parse(response.body["data"]["update_board"])

  puts "Success: #{result['success']}"
  puts "Undo data: #{result['undo_data']}"
end
```

**Example response:**
```json
{
  "success": true,
  "undo_data": "{\"undo_record_id\":123456,\"action_type\":\"update_board\"}"
}
```

## Check Before Update

Verify board exists before updating:

```ruby
def board_exists?(client, board_id)
  response = client.board.query(
    args: { ids: [board_id] },
    select: ["id"]
  )

  return false unless response.success?

  boards = response.body.dig("data", "boards")
  !boards.empty?
end

board_id = 1234567890

if board_exists?(client, board_id)
  response = client.board.update(
    args: {
      board_id: board_id,
      board_attribute: :name,
      new_value: "Updated Name"
    }
  )
else
  puts "Board not found"
end
```

## Update with Validation

Validate input before updating:

```ruby
def update_board_name(client, board_id, new_name)
  # Validate name
  if new_name.nil? || new_name.strip.empty?
    puts "✗ Name cannot be empty"
    return false
  end

  if new_name.length > 255
    puts "✗ Name too long (max 255 characters)"
    return false
  end

  # Update
  response = client.board.update(
    args: {
      board_id: board_id,
      board_attribute: :name,
      new_value: new_name
    }
  )

  if response.success?
    result = JSON.parse(response.body["data"]["update_board"])

    if result["success"]
      puts "✓ Board renamed to: #{new_name}"
      true
    else
      puts "✗ Update failed"
      false
    end
  else
    puts "✗ Request failed: #{response.status}"
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
update_board_name(client, 1234567890, "Q1 Marketing Campaigns")
```

## Batch Updates

Update multiple attributes sequentially:

```ruby
def update_board_details(client, board_id, name: nil, description: nil)
  updates = []

  if name
    updates << { attribute: :name, value: name }
  end

  if description
    updates << { attribute: :description, value: description }
  end

  updates.each do |update|
    response = client.board.update(
      args: {
        board_id: board_id,
        board_attribute: update[:attribute],
        new_value: update[:value]
      }
    )

    if response.success?
      result = JSON.parse(response.body["data"]["update_board"])

      if result["success"]
        puts "✓ Updated #{update[:attribute]}"
      else
        puts "✗ Failed to update #{update[:attribute]}"
      end
    else
      puts "✗ Request failed for #{update[:attribute]}"
    end
  end
end

# Usage
update_board_details(
  client,
  1234567890,
  name: "2024 Marketing Strategy",
  description: "Comprehensive marketing plan for fiscal year 2024"
)
```

**Output:**
```
✓ Updated name
✓ Updated description
```

## Error Handling

Handle common update errors:

```ruby
def safe_update_board(client, board_id, attribute, value)
  response = client.board.update(
    args: {
      board_id: board_id,
      board_attribute: attribute,
      new_value: value
    }
  )

  if response.success?
    result = JSON.parse(response.body["data"]["update_board"])

    if result["success"]
      puts "✓ Successfully updated #{attribute}"
      return true
    else
      puts "✗ Update rejected by API"
      return false
    end
  else
    puts "✗ Request failed with status: #{response.status}"

    if response.body["error_message"]
      puts "  Error: #{response.body['error_message']}"
    end

    return false
  end
rescue Monday::AuthorizationError
  puts "✗ No permission to update board #{board_id}"
  false
rescue Monday::InvalidRequestError => e
  puts "✗ Invalid request: #{e.message}"
  false
rescue Monday::Error => e
  puts "✗ API error: #{e.message}"
  false
rescue JSON::ParserError
  puts "✗ Failed to parse response"
  false
end

# Usage
safe_update_board(client, 1234567890, :name, "New Board Name")
```

## Verify Update

Confirm the change was applied:

```ruby
def update_and_verify(client, board_id, attribute, new_value)
  # Update
  response = client.board.update(
    args: {
      board_id: board_id,
      board_attribute: attribute,
      new_value: new_value
    }
  )

  return false unless response.success?

  result = JSON.parse(response.body["data"]["update_board"])
  return false unless result["success"]

  # Verify by querying
  verify_response = client.board.query(
    args: { ids: [board_id] },
    select: ["id", attribute.to_s]
  )

  if verify_response.success?
    board = verify_response.body.dig("data", "boards", 0)
    current_value = board[attribute.to_s]

    if current_value == new_value
      puts "✓ Update verified: #{attribute} = '#{new_value}'"
      true
    else
      puts "⚠ Update may not have applied correctly"
      puts "  Expected: '#{new_value}'"
      puts "  Got: '#{current_value}'"
      false
    end
  else
    puts "⚠ Could not verify update"
    false
  end
end

# Usage
update_and_verify(
  client,
  1234567890,
  :name,
  "Verified Board Name"
)
```

## Available Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `:name` | String | Board display name |
| `:description` | String | Board description text |
| `:communication` | String | Communication link or meeting ID |

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Attribute Values</span>
Only these three attributes can be updated via the `update_board` mutation. To change other properties (like permissions or workspace), use different methods.
:::

## Complete Example

Full update workflow with error handling:

```ruby
require "monday_ruby"
require "dotenv/load"
require "json"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# Board to update
board_id = 1234567890

puts "\n🔧 Updating Board Settings\n#{'=' * 50}\n"

# Update name
print "Updating name... "
name_response = client.board.update(
  args: {
    board_id: board_id,
    board_attribute: :name,
    new_value: "2024 Q1 Strategy"
  }
)

if name_response.success?
  result = JSON.parse(name_response.body["data"]["update_board"])
  puts result["success"] ? "✓" : "✗"
else
  puts "✗ (#{name_response.status})"
end

# Update description
print "Updating description... "
desc_response = client.board.update(
  args: {
    board_id: board_id,
    board_attribute: :description,
    new_value: "Strategic planning and execution for Q1 2024"
  }
)

if desc_response.success?
  result = JSON.parse(desc_response.body["data"]["update_board"])
  puts result["success"] ? "✓" : "✗"
else
  puts "✗ (#{desc_response.status})"
end

# Verify changes
puts "\nVerifying updates..."
verify_response = client.board.query(
  args: { ids: [board_id] },
  select: ["id", "name", "description"]
)

if verify_response.success?
  board = verify_response.body.dig("data", "boards", 0)

  puts "\n#{'=' * 50}"
  puts "Updated Board:"
  puts "  Name: #{board['name']}"
  puts "  Description: #{board['description']}"
  puts "#{'=' * 50}\n"
else
  puts "✗ Could not verify changes"
end
```

## Next Steps

- [Archive boards](/guides/boards/delete)
- [Duplicate boards](/guides/boards/duplicate)
- [Query boards](/guides/boards/query)
- [Work with columns](/guides/columns/create)
