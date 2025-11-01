# Activity Log

Access board activity logs via the `client.activity_log` resource.

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>What are Activity Logs?</span>
Activity logs track all changes and events that occur on a board, including item creation, column changes, updates, and more.
:::

## Methods

### query

Retrieves activity logs for one or more boards.

```ruby
client.activity_log.query(board_ids, args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `board_ids` | Integer or Array | - | Board ID(s) to retrieve logs for (required) |
| `args` | Hash | `{}` | Query arguments for filtering |
| `select` | Array | `["id", "event", "data"]` | Fields to retrieve |

**Returns:** `Monday::Response`

**Common args:**
- `limit` - Integer - Maximum number of logs to return (default: 25, max: 100)
- `page` - Integer - Page number for pagination
- `from` - String - ISO 8601 timestamp to start from
- `to` - String - ISO 8601 timestamp to end at
- `user_ids` - Array - Filter by specific user IDs

**Available Fields:**

- `id` - Activity log ID (UUID)
- `event` - Event type (e.g., "create_pulse", "update_board_name", "create_column")
- `data` - JSON string with event details
- `created_at` - When the event occurred
- `entity` - Entity type (e.g., "pulse", "board", "column")
- `user_id` - ID of user who performed the action
- `account_id` - Account ID

**Response Structure:**

Activity logs are nested under boards:

```ruby
boards = response.body.dig("data", "boards")
logs = boards.first&.dig("activity_logs") || []
```

**Event Types:**

Common event types include:

- `create_pulse` - Item created
- `update_name` - Item name changed
- `create_column` - Column created
- `update_column_value` - Column value updated
- `create_group` - Group created
- `update_board_name` - Board name changed
- `archive_pulse` - Item archived
- `delete_pulse` - Item deleted
- `move_pulse_to_group` - Item moved to different group

**Example:**

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.activity_log.query(
  1234567890,  # board_id
  args: { limit: 50 }
)

if response.success?
  boards = response.body.dig("data", "boards")
  logs = boards.first&.dig("activity_logs") || []

  puts "Found #{logs.length} activity logs"
  logs.each do |log|
    puts "  • #{log['event']}: #{log['id']}"
  end
end
```

**Output:**
```
Found 5 activity logs
  • create_pulse: 3d4cf392-99d5-44ed-a4ed-9cdf1bf80e3f
  • board_workspace_id_changed: f77e1ec3-f425-40da-ba71-7cc3a711c7f1
  • update_board_name: 25b65ed3-f3ff-49bd-bc53-62617d6a18d5
  • create_column: e8850206-aad9-46ee-8b05-ce1c5d57f9f8
  • create_group: ed844d08-093a-46e6-ab41-e8700c530d83
```

**GraphQL:** `query { boards { activity_logs { ... } } }`

**See:** [monday.com activity_logs query](https://developer.monday.com/api-reference/reference/activity-logs)

## Parse Activity Data

Activity log data is returned as a JSON string. Parse it to access details:

```ruby
require "json"

response = client.activity_log.query(
  1234567890,
  args: { limit: 10 },
  select: ["id", "event", "data", "created_at"]
)

if response.success?
  boards = response.body.dig("data", "boards")
  logs = boards.first&.dig("activity_logs") || []

  logs.each do |log|
    data = JSON.parse(log["data"])

    case log["event"]
    when "create_pulse"
      puts "Item created: #{data['pulse_name']} (ID: #{data['pulse_id']})"
    when "update_column_value"
      puts "Column updated: #{data['column_id']} on item #{data['pulse_id']}"
    when "create_group"
      puts "Group created: #{data['group_title']}"
    end
  end
end
```

## Filter by Time Range

Retrieve logs for a specific time period:

```ruby
response = client.activity_log.query(
  1234567890,
  args: {
    from: "2024-01-01T00:00:00Z",
    to: "2024-12-31T23:59:59Z",
    limit: 100
  },
  select: ["id", "event", "created_at"]
)

if response.success?
  boards = response.body.dig("data", "boards")
  logs = boards.first&.dig("activity_logs") || []

  puts "Activity from Jan 1 to Dec 31, 2024: #{logs.length} events"
end
```

## Filter by User

Get activity logs for specific users:

```ruby
response = client.activity_log.query(
  1234567890,
  args: {
    user_ids: [12345678, 87654321],
    limit: 50
  },
  select: ["id", "event", "user_id", "created_at"]
)

if response.success?
  boards = response.body.dig("data", "boards")
  logs = boards.first&.dig("activity_logs") || []

  puts "User activity: #{logs.length} events"
end
```

## Multiple Boards

Query logs from multiple boards:

```ruby
response = client.activity_log.query(
  [1234567890, 2345678901],  # Multiple board IDs
  args: { limit: 25 },
  select: ["id", "event", "created_at"]
)

if response.success?
  boards = response.body.dig("data", "boards")

  boards.each do |board|
    logs = board["activity_logs"] || []
    puts "Board #{board['id']}: #{logs.length} recent events"
  end
end
```

## Response Structure

All methods return a `Monday::Response` object. Access data using:

```ruby
response.success?  # => true/false
response.status    # => 200
response.body      # => Hash with GraphQL response
```

### Typical Response Pattern

```ruby
response = client.activity_log.query(
  1234567890,
  args: { limit: 10 }
)

if response.success?
  boards = response.body.dig("data", "boards")
  logs = boards.first&.dig("activity_logs") || []

  # Work with logs
else
  # Handle error
end
```

## Constants

### DEFAULT_SELECT

Default fields returned by the activity log query:

```ruby
["id", "event", "data"]
```

## Error Handling

Common errors when working with activity logs:

- `Monday::AuthorizationError` - Invalid or missing API token
- `Monday::InvalidRequestError` - Invalid board ID
- `Monday::Error` - Invalid field or other API errors

**Example:**

```ruby
begin
  response = client.activity_log.query(
    123,  # Invalid ID
    args: { limit: 10 }
  )
rescue Monday::InvalidRequestError => e
  puts "Error: #{e.message}"
end
```

See the [Error Handling guide](/guides/advanced/errors) for more details.

## Use Cases

### Audit Trail

Track all changes on a board:

```ruby
require "json"

response = client.activity_log.query(
  1234567890,
  args: {
    from: "2024-01-01T00:00:00Z",
    limit: 100
  },
  select: ["id", "event", "data", "created_at", "user_id"]
)

if response.success?
  boards = response.body.dig("data", "boards")
  logs = boards.first&.dig("activity_logs") || []

  puts "Audit Trail"
  puts "=" * 60

  logs.each do |log|
    data = JSON.parse(log["data"])
    timestamp = log["created_at"]
    user_id = log["user_id"]

    puts "\n[#{timestamp}] User #{user_id}"
    puts "  Event: #{log['event']}"
    puts "  Details: #{data.inspect}"
  end
end
```

### Monitor Item Creation

Track when new items are created:

```ruby
require "json"

response = client.activity_log.query(
  1234567890,
  args: { limit: 100 },
  select: ["id", "event", "data", "created_at"]
)

if response.success?
  boards = response.body.dig("data", "boards")
  logs = boards.first&.dig("activity_logs") || []

  created_items = logs.select { |log| log["event"] == "create_pulse" }

  puts "Recently Created Items:"
  created_items.each do |log|
    data = JSON.parse(log["data"])
    puts "  • #{data['pulse_name']} (ID: #{data['pulse_id']})"
  end
end
```

### Track Column Changes

Monitor column value updates:

```ruby
require "json"

response = client.activity_log.query(
  1234567890,
  args: { limit: 50 },
  select: ["id", "event", "data"]
)

if response.success?
  boards = response.body.dig("data", "boards")
  logs = boards.first&.dig("activity_logs") || []

  column_updates = logs.select { |log| log["event"] == "update_column_value" }

  puts "Column Updates: #{column_updates.length}"
  column_updates.each do |log|
    data = JSON.parse(log["data"])
    puts "  • Column '#{data['column_id']}' updated on item #{data['pulse_id']}"
  end
end
```

## Related Resources

- [Board](/reference/resources/board) - Boards containing activity logs
- [Item](/reference/resources/item) - Items tracked in activity logs
- [Update](/reference/resources/update) - Updates/comments on items

## External References

- [monday.com Activity Logs API](https://developer.monday.com/api-reference/reference/activity-logs)
- [GraphQL API Overview](https://developer.monday.com/api-reference/docs/introduction-to-graphql)
