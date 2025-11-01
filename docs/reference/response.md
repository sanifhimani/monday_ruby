# Response

The `Monday::Response` class wraps HTTP responses from the monday.com API.

## Overview

Every request to monday.com returns a `Monday::Response` object that encapsulates the HTTP response status, parsed JSON body, and headers. This wrapper provides convenient access to response data and helps detect errors.

All resource methods (`client.board.query`, `client.item.create`, etc.) return a `Monday::Response` object.

## Attributes

All attributes are read-only (`attr_reader`).

| Attribute | Type | Description |
|-----------|------|-------------|
| `status` | Integer | HTTP status code (200, 400, 401, 404, 500, etc.) |
| `body` | Hash | Parsed JSON response body containing GraphQL data |
| `headers` | Hash | HTTP response headers as key-value pairs |

**Example:**

```ruby
response = client.board.query(args: { ids: [123] })

response.status   # => 200
response.body     # => { "data" => { "boards" => [...] } }
response.headers  # => { "content-type" => "application/json", ... }
```

## Methods

### success?

Determines if the request was successful.

```ruby
response.success?  # => true or false
```

**Returns:** Boolean

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>monday.com API Quirk</span>
monday.com returns HTTP 200 status codes even for some GraphQL errors. The `success?` method checks BOTH the status code (200-299) AND the response body for error keys.
:::

**Error Detection:**

The method returns `false` if:
- HTTP status code is outside 200-299 range, OR
- Response body contains any of these keys: `"errors"`, `"error_code"`, `"error_message"`

**Example:**

```ruby
response = client.board.query(args: { ids: [123] })

if response.success?
  # Safe to access data
  boards = response.body.dig("data", "boards")
else
  # Handle error
  errors = response.body["errors"]
end
```

## Response Structure

### Successful GraphQL Response

All successful GraphQL responses follow this structure:

```ruby
{
  "data" => {
    "boards" => [
      { "id" => "123", "name" => "My Board" }
    ]
  },
  "account_id" => 12345678
}
```

The actual data is nested under the `"data"` key, with the resource name as the next level.

**Common GraphQL response patterns:**

| Operation | Path to data |
|-----------|--------------|
| Query boards | `response.body.dig("data", "boards")` |
| Create board | `response.body.dig("data", "create_board")` |
| Query items | `response.body.dig("data", "items")` |
| Create item | `response.body.dig("data", "create_item")` |
| Duplicate board | `response.body.dig("data", "duplicate_board", "board")` |

### Error Response

Error responses contain an `"errors"` array:

```ruby
{
  "errors" => [
    {
      "message" => "User unauthorized to perform action",
      "extensions" => {
        "code" => "AuthorizationException",
        "error_code" => "AuthorizationException"
      }
    }
  ],
  "account_id" => 12345678
}
```

Alternative error formats:

```ruby
# Simple error
{
  "error_message" => "Invalid token",
  "error_code" => "InvalidTokenException"
}

# Generic error
{
  "errors" => "Some error message"
}
```

## Accessing Data

### Using dig for Safe Access

Always use `dig` to safely navigate nested response data:

```ruby
response = client.board.query(args: { ids: [123] })

# Safe - returns nil if any key is missing
boards = response.body.dig("data", "boards")

# Unsafe - raises error if key is missing
boards = response.body["data"]["boards"]  # Don't do this
```

### Accessing Nested Data

**Single board:**

```ruby
response = client.board.query(args: { ids: [123] })

boards = response.body.dig("data", "boards")
board = boards&.first

puts board["name"]       # => "My Board"
puts board["id"]         # => "123"
```

**Board with items:**

```ruby
response = client.board.query(
  args: { ids: [123] },
  select: ["id", "name", { items: ["id", "name"] }]
)

board = response.body.dig("data", "boards", 0)
items = board["items"]

items.each do |item|
  puts item["name"]
end
```

**Paginated items:**

```ruby
response = client.board.items_page(
  board_ids: 123,
  limit: 50
)

items_page = response.body.dig("data", "boards", 0, "items_page")
items = items_page["items"]
cursor = items_page["cursor"]

puts "Retrieved #{items.length} items"
puts "Next cursor: #{cursor}"
```

### Handling Missing Data

```ruby
response = client.board.query(args: { ids: [999] })

boards = response.body.dig("data", "boards")

if boards.nil? || boards.empty?
  puts "No boards found"
else
  puts "Found #{boards.length} boards"
end
```

## Error Responses

### Checking for Errors

```ruby
response = client.board.query(args: { ids: [123] })

unless response.success?
  if response.body["errors"]
    errors = response.body["errors"]
    errors.each do |error|
      puts "Error: #{error['message']}"
    end
  elsif response.body["error_message"]
    puts "Error: #{response.body['error_message']}"
  end
end
```

### Error Response Examples

**Authorization Error (HTTP 200 with errors in body):**

```ruby
{
  "errors" => [
    {
      "message" => "User unauthorized to perform action",
      "extensions" => {
        "code" => "AuthorizationException"
      }
    }
  ],
  "account_id" => 12345678
}

response.status    # => 200
response.success?  # => false (because errors key exists)
```

**Invalid Token (HTTP 401):**

```ruby
{
  "error_message" => "Invalid token",
  "error_code" => "InvalidTokenException"
}

response.status    # => 401
response.success?  # => false
```

**Rate Limit (HTTP 429):**

```ruby
{
  "error_message" => "You have reached the rate limit",
  "error_code" => "ComplexityException"
}

response.status    # => 429
response.success?  # => false
```

**Invalid Query (HTTP 200 with errors in body):**

```ruby
{
  "errors" => [
    {
      "message" => "Field 'invalid_field' doesn't exist on type 'Board'",
      "locations" => [{ "line" => 1, "column" => 20 }]
    }
  ]
}

response.status    # => 200
response.success?  # => false (because errors key exists)
```

## Usage Examples

### Basic Query

```ruby
response = client.board.query(args: { ids: [123] })

if response.success?
  boards = response.body.dig("data", "boards")
  puts "Found #{boards.length} boards"
else
  puts "Request failed with status #{response.status}"
end
```

### Create Operation

```ruby
response = client.board.create(
  args: {
    board_name: "New Board",
    board_kind: :public
  }
)

if response.success?
  board = response.body.dig("data", "create_board")
  puts "Created board #{board['id']}: #{board['name']}"
else
  errors = response.body["errors"]
  puts "Failed to create board: #{errors}"
end
```

### Handling Nested Data

```ruby
response = client.item.query(
  args: { ids: [456] },
  select: ["id", "name", { column_values: ["id", "text", "value"] }]
)

if response.success?
  items = response.body.dig("data", "items")
  item = items&.first

  if item
    puts "Item: #{item['name']}"

    column_values = item["column_values"]
    column_values&.each do |cv|
      puts "  #{cv['id']}: #{cv['text']}"
    end
  end
end
```

### Checking Response Headers

```ruby
response = client.board.query(args: { ids: [123] })

puts "Status: #{response.status}"
puts "Content-Type: #{response.headers['content-type']}"
puts "Rate Limit: #{response.headers['x-ratelimit-remaining']}"
```

### Processing Multiple Results

```ruby
response = client.board.query(
  args: { ids: [123, 456, 789] }
)

if response.success?
  boards = response.body.dig("data", "boards") || []

  boards.each do |board|
    puts "Board #{board['id']}: #{board['name']}"
  end

  puts "\nTotal: #{boards.length} boards"
else
  puts "Failed to fetch boards"
end
```

## Best Practices

### Always Check success?

Never assume a request succeeded. Always check before accessing data:

```ruby
# Good
response = client.board.query(args: { ids: [123] })

if response.success?
  boards = response.body.dig("data", "boards")
  # Work with boards
else
  # Handle error
end

# Bad - will raise error if request fails
boards = client.board.query(args: { ids: [123] }).body["data"]["boards"]
```

### Use dig for Safe Navigation

Use `dig` to safely access nested data:

```ruby
# Good - returns nil if any key is missing
board = response.body.dig("data", "boards", 0)
name = board&.dig("name")

# Bad - raises error if key is missing
name = response.body["data"]["boards"][0]["name"]
```

### Handle nil Results

Always check for nil before iterating:

```ruby
# Good
boards = response.body.dig("data", "boards") || []
boards.each { |board| puts board["name"] }

# Or
boards = response.body.dig("data", "boards")
if boards
  boards.each { |board| puts board["name"] }
end

# Bad - raises error if boards is nil
boards = response.body.dig("data", "boards")
boards.each { |board| puts board["name"] }
```

### Store Response Data

Extract data from the response before working with it:

```ruby
# Good
response = client.board.query(args: { ids: [123] })

if response.success?
  boards = response.body.dig("data", "boards")
  # Now work with boards array
end

# Less efficient - accessing response.body multiple times
if response.success?
  response.body.dig("data", "boards").each do |board|
    # ...
  end
end
```

### Check Both success? and Data Presence

Some queries may succeed but return empty results:

```ruby
response = client.board.query(args: { ids: [999] })

if response.success?
  boards = response.body.dig("data", "boards")

  if boards && !boards.empty?
    # Process boards
  else
    puts "No boards found with ID 999"
  end
else
  puts "Request failed: #{response.status}"
end
```

## GraphQL Response Format

### Data Wrapper

All successful GraphQL responses wrap data in a `"data"` key:

```ruby
{
  "data" => {
    # Actual response data here
  },
  "account_id" => 12345678
}
```

### Query Responses

Query responses use plural resource names:

```ruby
# boards query
{
  "data" => {
    "boards" => [...]
  }
}

# items query
{
  "data" => {
    "items" => [...]
  }
}
```

### Mutation Responses

Mutation responses use the mutation name:

```ruby
# create_board
{
  "data" => {
    "create_board" => { "id" => "123", "name" => "New Board" }
  }
}

# update_board (returns JSON string)
{
  "data" => {
    "update_board" => '{"success":true,"undo_data":"..."}'
  }
}

# duplicate_board (nested under "board")
{
  "data" => {
    "duplicate_board" => {
      "board" => { "id" => "456", "name" => "Duplicated Board" }
    }
  }
}
```

### Error Structure

Errors use the `"errors"` array:

```ruby
{
  "errors" => [
    {
      "message" => "Error description",
      "extensions" => {
        "code" => "ErrorCode"
      }
    }
  ],
  "account_id" => 12345678
}
```

## Related Documentation

- [Client](/reference/client) - Making API requests
- [Error Handling](/guides/advanced/errors) - Handling exceptions
- [Board Resource](/reference/resources/board) - Example resource usage
- [Item Resource](/reference/resources/item) - Example resource usage

## External References

- [monday.com GraphQL API](https://developer.monday.com/api-reference/docs/introduction-to-graphql)
- [GraphQL Response Format](https://graphql.org/learn/serving-over-http/)
