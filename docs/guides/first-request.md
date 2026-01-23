# Make Your First Request

Query boards from your monday.com account using the Ruby client.

## Prerequisites

- [Installed and configured](/guides/installation) monday_ruby
- [Set up authentication](/guides/authentication) with your API token

## Basic Query

The simplest request fetches all boards you have access to:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new
response = client.board.query
```

This returns all boards with their ID, name, and description.

## Check Response Status

Always verify the request succeeded:

```ruby
client = Monday::Client.new
response = client.board.query

if response.success?
  puts "Request succeeded!"
  puts "Status code: #{response.status}"
else
  puts "Request failed: #{response.status}"
end
```

The `success?` method returns `true` for 2xx status codes and when there are no API errors.

## Access Response Data

Extract data from the response body:

```ruby
response = client.board.query

if response.success?
  boards = response.body["data"]["boards"]

  puts "Found #{boards.length} boards:\n"

  boards.each do |board|
    puts "  • #{board['name']} (ID: #{board['id']})"
  end
end
```

**Example output:**
```
Found 3 boards:
  • Marketing Campaigns (ID: 1234567890)
  • Product Roadmap (ID: 2345678901)
  • Team Tasks (ID: 3456789012)
```

## Using dig for Safe Access

Use `dig` to safely navigate nested hashes:

```ruby
response = client.board.query

boards = response.body.dig("data", "boards")

if boards
  first_board = boards.first
  board_name = first_board.dig("name")

  puts "First board: #{board_name}"
else
  puts "No boards found"
end
```

This prevents `NoMethodError` if keys don't exist.

## Filter Results

Query specific boards by ID:

```ruby
response = client.board.query(
  args: { ids: [1234567890, 2345678901] }
)

if response.success?
  boards = response.body.dig("data", "boards")
  puts "Retrieved #{boards.length} specific boards"
end
```

## Customize Fields

Select only the fields you need:

```ruby
response = client.board.query(
  select: ["id", "name"]  # Skip description
)

if response.success?
  boards = response.body.dig("data", "boards")

  boards.each do |board|
    # Only id and name are present
    puts "#{board['id']}: #{board['name']}"
  end
end
```

:::tip Performance Tip
Only request fields you need. Smaller responses are faster and use less bandwidth.
:::

## Query Nested Data

Fetch boards with their items:

```ruby
response = client.board.query(
  args: { ids: [1234567890] },
  select: [
    "id",
    "name",
    {
      items: ["id", "name"]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "boards", 0)

  puts "Board: #{board['name']}"
  puts "Items:"

  board["items"].each do |item|
    puts "  • #{item['name']}"
  end
end
```

**Example output:**
```
Board: Marketing Campaigns
Items:
  • Q1 Campaign Plan
  • Social Media Strategy
  • Email Newsletter Design
```

## Response Structure

All responses follow this structure:

```ruby
{
  "data" => {
    "boards" => [
      {
        "id" => "1234567890",
        "name" => "Board Name",
        "description" => "Board description"
      }
    ]
  }
}
```

The root `data` key contains the query results. Resource arrays (like `boards`) are always arrays, even for single items.

## Handle Errors

Check for specific error conditions:

```ruby
response = client.board.query

if response.success?
  boards = response.body.dig("data", "boards")
  puts "Success! Found #{boards.length} boards"
else
  puts "Request failed with status: #{response.status}"

  # Check for API errors
  if response.body["errors"]
    puts "API Errors:"
    response.body["errors"].each do |error|
      puts "  • #{error['message']}"
    end
  end
end
```

## Common Response Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Process the data |
| 401 | Unauthorized | Check your API token |
| 429 | Rate limited | Wait and retry |
| 500 | Server error | Retry with backoff |

:::warning 200 Doesn't Always Mean Success
monday.com returns status 200 even for some errors. Always check `response.success?` which also validates the response body for error fields.
:::

## Complete Example

Put it all together:

:::details{title="Complete Example"}

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# Query boards with items
response = client.board.query(
  args: { limit: 5 },
  select: [
    "id",
    "name",
    "description",
    {
      items: ["id", "name"]
    }
  ]
)

if response.success?
  boards = response.body.dig("data", "boards")

  puts "\n📋 Your Boards\n#{'=' * 50}\n"

  boards.each do |board|
    puts "\n#{board['name']}"
    puts "  ID: #{board['id']}"
    puts "  Items: #{board['items']&.length || 0}"

    if board['description'] && !board['description'].empty?
      puts "  Description: #{board['description']}"
    end
  end

  puts "\n#{'=' * 50}"
  puts "Total: #{boards.length} boards"
else
  puts "❌ Request failed"
  puts "Status: #{response.status}"

  if response.body["errors"]
    puts "\nErrors:"
    response.body["errors"].each do |error|
      puts "  • #{error['message']}"
    end
  end
end
```
:::
