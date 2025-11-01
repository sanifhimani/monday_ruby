# Errors

Exception classes for handling monday.com API errors.

## Overview

The monday_ruby gem provides a comprehensive error handling system that maps HTTP status codes and monday.com GraphQL error codes to specific Ruby exception classes. All errors inherit from `Monday::Error`, making it easy to catch and handle monday.com-related errors in your application.

### When Errors Are Raised

Errors are raised in two scenarios:

1. **HTTP Status Codes**: Non-2xx status codes (400, 401, 403, 404, 429, 500)
2. **GraphQL Error Codes**: Even when HTTP status is 200, GraphQL error_code values trigger specific exceptions

```ruby
# HTTP 401 raises Monday::AuthorizationError
client = Monday::Client.new(token: "invalid_token")
client.account.query
# => Monday::AuthorizationError

# HTTP 200 with error_code raises Monday::InvalidRequestError
client.board.query(args: {ids: [999999]})
# => Monday::InvalidRequestError: InvalidBoardIdException
```

## Error Hierarchy

All errors inherit from `Monday::Error < StandardError`:

```
Monday::Error
├── Monday::AuthorizationError
├── Monday::InvalidRequestError
├── Monday::ResourceNotFoundError
├── Monday::RateLimitError
├── Monday::InternalServerError
└── Monday::ComplexityError
```

## Base Error Class

### Monday::Error

Base error class from which all monday_ruby exceptions inherit.

**Inherits:** `StandardError`

**Attributes:**

| Name | Type | Description |
|------|------|-------------|
| `message` | String | Human-readable error message |
| `code` | Integer or String | HTTP status code or GraphQL error code |
| `response` | Monday::Response | Full response object (if available) |

**Methods:**

| Name | Returns | Description |
|------|---------|-------------|
| `error_data` | Hash | Additional error metadata from `response.body["error_data"]` |

**Example:**

```ruby
begin
  client.board.query(args: {ids: [123]})
rescue Monday::Error => e
  puts e.message    # => "The board does not exist..."
  puts e.code       # => "InvalidBoardIdException" or 404
  puts e.response   # => Monday::Response object
  puts e.error_data # => {"board_id" => 123}
end
```

## Exception Classes

### Monday::AuthorizationError

Raised when authentication fails or the user lacks required permissions.

**HTTP Status Codes:** 401, 403

**GraphQL Error Codes:**
- `UserUnauthorizedException`
- `USER_UNAUTHORIZED`

**Common Causes:**
- Invalid or expired API token
- Token doesn't have required scopes/permissions
- Token has been revoked
- Attempting to access resources without proper authorization

**Example:**

```ruby
begin
  client = Monday::Client.new(token: "invalid_token")
  client.account.query(select: ["id", "name"])

rescue Monday::AuthorizationError => e
  puts "Authentication failed: #{e.message}"
  puts "Please verify your API token in the monday.com Developer Portal"
end
```

**Typical Response:**

```json
{
  "errors": ["Not Authenticated"],
  "status": 401
}
```

**See:** [Error Handling guide](/guides/advanced/errors#authorizationerror-401-403)

---

### Monday::InvalidRequestError

Raised when request parameters are invalid or malformed.

**HTTP Status Code:** 400

**GraphQL Error Codes:**
- `InvalidUserIdException`
- `InvalidVersionException`
- `InvalidColumnIdException`
- `InvalidItemIdException`
- `InvalidSubitemIdException`
- `InvalidBoardIdException`
- `InvalidGroupIdException`
- `InvalidArgumentException`
- `CreateBoardException`
- `ItemsLimitationException`
- `ItemNameTooLongException`
- `ColumnValueException`
- `CorrectedValueException`
- `InvalidWorkspaceIdException`

**Common Causes:**
- Invalid board, item, column, or group IDs
- Malformed GraphQL query syntax
- Invalid column values or formats
- Item names exceeding 255 characters
- Missing required parameters
- Attempting to create boards with invalid attributes

**Example:**

```ruby
begin
  response = client.item.create(
    args: {
      board_id: 999999,  # Invalid board ID
      item_name: "New Task"
    },
    select: ["id", "name"]
  )

rescue Monday::InvalidRequestError => e
  puts "Invalid request: #{e.message}"

  # Access specific error details
  if e.error_data["board_id"]
    puts "Invalid board ID: #{e.error_data["board_id"]}"
  elsif e.error_data["item_id"]
    puts "Invalid item ID: #{e.error_data["item_id"]}"
  elsif e.error_data["column_id"]
    puts "Invalid column ID: #{e.error_data["column_id"]}"
  end
end
```

**Typical Response:**

```json
{
  "error_message": "The board does not exist. Please check your board ID and try again",
  "error_code": "InvalidBoardIdException",
  "error_data": {"board_id": 999999},
  "status_code": 200
}
```

**See:** [Error Handling guide](/guides/advanced/errors#invalidrequesterror-400)

---

### Monday::ResourceNotFoundError

Raised when a requested resource does not exist.

**HTTP Status Code:** 404

**GraphQL Error Codes:**
- `ResourceNotFoundException`

**Common Causes:**
- Resource has been deleted
- Resource never existed
- User doesn't have access to the resource
- Incorrect resource ID

**Example:**

```ruby
begin
  response = client.folder.delete(args: {folder_id: 123456})

rescue Monday::ResourceNotFoundError => e
  puts "Resource not found: #{e.message}"
  puts "The folder may have already been deleted"

  # This is often an acceptable outcome
  # No need to re-raise
end
```

**Typical Response:**

```json
{
  "error_message": "The folder does not exist. Please check your folder ID and try again",
  "error_code": "ResourceNotFoundException",
  "error_data": {"folder_id": 123456},
  "status_code": 200
}
```

**See:** [Error Handling guide](/guides/advanced/errors#resourcenotfounderror-404)

---

### Monday::RateLimitError

Raised when API rate limits are exceeded.

**HTTP Status Code:** 429

**GraphQL Error Codes:**
- `ComplexityException` (when used for rate limiting)
- `COMPLEXITY_BUDGET_EXHAUSTED`

**Common Causes:**
- Too many requests in a short time period
- Exceeding complexity budget (10,000,000 per minute for queries)
- Exceeding mutation limit (60 per minute per user)

**Rate Limits:**
- **Queries**: Complexity-based, max 10,000,000 complexity per minute
- **Mutations**: 60 requests per minute per user

**Example:**

```ruby
begin
  response = client.board.query(
    args: {limit: 100},
    select: ["id", "name", {"items" => ["id", "name", "column_values"]}]
  )

rescue Monday::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"

  # Wait before retrying
  puts "Waiting 60 seconds before retry..."
  sleep 60
  retry
end
```

**Typical Response:**

```json
{
  "error_message": "You have exceeded your rate limit",
  "error_code": "COMPLEXITY_BUDGET_EXHAUSTED",
  "status_code": 429
}
```

**See:**
- [Error Handling guide](/guides/advanced/errors#ratelimiterror-429)
- [Rate Limiting guide](/guides/advanced/rate-limiting)

---

### Monday::InternalServerError

Raised when monday.com's servers encounter an internal error.

**HTTP Status Code:** 500

**GraphQL Error Codes:**
- `INTERNAL_SERVER_ERROR`

**Common Causes:**
- monday.com service outages or degradations
- Server-side bugs in monday.com API
- Temporary infrastructure issues
- Invalid data causing server-side errors

**Example:**

```ruby
def create_with_retry(client, args, max_retries: 3)
  retry_count = 0

  begin
    client.item.create(args: args, select: ["id", "name"])

  rescue Monday::InternalServerError => e
    retry_count += 1

    if retry_count < max_retries
      delay = 2 ** retry_count  # Exponential backoff: 2s, 4s, 8s
      puts "Server error (attempt #{retry_count}/#{max_retries}). Retrying in #{delay}s..."
      sleep delay
      retry
    else
      puts "Server error persists after #{max_retries} attempts"
      raise
    end
  end
end
```

**Typical Response:**

```json
{
  "status_code": 500,
  "error_message": "Internal server error",
  "error_code": "INTERNAL_SERVER_ERROR"
}
```

**See:** [Error Handling guide](/guides/advanced/errors#internalservererror-500)

---

### Monday::ComplexityError

Raised when GraphQL query complexity is too high.

**GraphQL Error Codes:**
- `ComplexityException`

**Common Causes:**
- Requesting too many nested fields
- Querying too many items at once
- Complex queries with deep nesting
- Requesting large amounts of data in a single query

**Example:**

```ruby
begin
  # This query might be too complex
  response = client.board.query(
    args: {limit: 100},
    select: [
      "id",
      "name",
      {"groups" => [
        "id",
        "title",
        {"items" => [
          "id",
          "name",
          {"column_values" => ["id", "text", "value"]}
        ]}
      ]}
    ]
  )

rescue Monday::ComplexityError => e
  puts "Query too complex: #{e.message}"

  # Simplify the query
  response = client.board.query(
    args: {limit: 25},  # Reduce limit
    select: ["id", "name", {"groups" => ["id", "title"]}]  # Less nesting
  )
end
```

**See:**
- [Error Handling guide](/guides/advanced/errors)
- [Complex Queries guide](/guides/advanced/complex-queries)

## Error Code Mapping

### HTTP Status Codes

| Status Code | Exception Class |
|-------------|----------------|
| 400 | `Monday::InvalidRequestError` |
| 401 | `Monday::AuthorizationError` |
| 403 | `Monday::AuthorizationError` |
| 404 | `Monday::ResourceNotFoundError` |
| 429 | `Monday::RateLimitError` |
| 500 | `Monday::InternalServerError` |
| Other | `Monday::Error` |

### GraphQL Error Codes

| Error Code | Exception Class | HTTP Status |
|------------|----------------|-------------|
| `UserUnauthorizedException` | `Monday::AuthorizationError` | 403 |
| `USER_UNAUTHORIZED` | `Monday::AuthorizationError` | 403 |
| `ResourceNotFoundException` | `Monday::ResourceNotFoundError` | 404 |
| `InvalidUserIdException` | `Monday::InvalidRequestError` | 400 |
| `InvalidVersionException` | `Monday::InvalidRequestError` | 400 |
| `InvalidColumnIdException` | `Monday::InvalidRequestError` | 400 |
| `InvalidItemIdException` | `Monday::InvalidRequestError` | 400 |
| `InvalidSubitemIdException` | `Monday::InvalidRequestError` | 400 |
| `InvalidBoardIdException` | `Monday::InvalidRequestError` | 400 |
| `InvalidGroupIdException` | `Monday::InvalidRequestError` | 400 |
| `InvalidArgumentException` | `Monday::InvalidRequestError` | 400 |
| `CreateBoardException` | `Monday::InvalidRequestError` | 400 |
| `ItemsLimitationException` | `Monday::InvalidRequestError` | 400 |
| `ItemNameTooLongException` | `Monday::InvalidRequestError` | 400 |
| `ColumnValueException` | `Monday::InvalidRequestError` | 400 |
| `CorrectedValueException` | `Monday::InvalidRequestError` | 400 |
| `InvalidWorkspaceIdException` | `Monday::InvalidRequestError` | 400 |
| `ComplexityException` | `Monday::ComplexityError` or `Monday::RateLimitError` | 429 |
| `COMPLEXITY_BUDGET_EXHAUSTED` | `Monday::RateLimitError` | 429 |
| `INTERNAL_SERVER_ERROR` | `Monday::InternalServerError` | 500 |

## Rescue Patterns

### Catch All monday.com Errors

```ruby
begin
  response = client.board.query(args: {ids: [123]})
rescue Monday::Error => e
  puts "monday.com error: #{e.message}"
  puts "Error code: #{e.code}"
end
```

### Catch Specific Error Types

```ruby
begin
  response = client.item.create(
    args: {board_id: 123, item_name: "Task"},
    select: ["id", "name"]
  )

rescue Monday::AuthorizationError => e
  puts "Authentication failed"

rescue Monday::InvalidRequestError => e
  puts "Invalid request: #{e.message}"

rescue Monday::RateLimitError => e
  puts "Rate limited. Waiting..."
  sleep 60
  retry

rescue Monday::Error => e
  puts "Unexpected error: #{e.message}"
end
```

### Access Error Details

```ruby
begin
  client.board.delete(999999)

rescue Monday::Error => e
  # Message
  puts e.message
  # => "The board does not exist. Please check your board ID and try again"

  # Code
  puts e.code
  # => "InvalidBoardIdException" or 404

  # Response object
  puts e.response.status
  # => 200 or 404

  puts e.response.body
  # => {"error_message" => "...", "error_code" => "...", ...}

  # Error data
  puts e.error_data
  # => {"board_id" => 999999}
end
```

### Multiple Rescue Blocks

```ruby
def safe_create_item(client, board_id, item_name)
  client.item.create(
    args: {board_id: board_id, item_name: item_name},
    select: ["id", "name"]
  )

rescue Monday::AuthorizationError => e
  logger.error("Auth error: #{e.message}")
  nil

rescue Monday::InvalidRequestError => e
  logger.warn("Invalid input: #{e.message}")
  nil

rescue Monday::ResourceNotFoundError => e
  logger.info("Resource not found: #{e.message}")
  nil

rescue Monday::RateLimitError => e
  logger.warn("Rate limited, retrying...")
  sleep 60
  retry

rescue Monday::InternalServerError => e
  logger.error("Server error: #{e.message}")
  nil

rescue Monday::Error => e
  logger.error("Unexpected error: #{e.class} - #{e.message}")
  raise  # Re-raise unexpected errors
end
```

## Usage Examples

### Basic Error Handling

```ruby
response = client.board.query(args: {ids: [123]})

if response.success?
  boards = response.body["data"]["boards"]
  puts "Found #{boards.length} boards"
else
  puts "Request failed: #{response.body["error_message"]}"
end
```

### With Retry Logic

```ruby
max_retries = 3
retry_count = 0

begin
  response = client.item.create(
    args: {board_id: 123, item_name: "New Task"},
    select: ["id", "name"]
  )

  item = response.body["data"]["create_item"]

rescue Monday::RateLimitError => e
  # Always retry rate limits
  sleep 60
  retry

rescue Monday::InternalServerError => e
  retry_count += 1

  if retry_count < max_retries
    delay = 2 ** retry_count
    sleep delay
    retry
  else
    raise
  end

rescue Monday::Error => e
  puts "Error: #{e.message}"
  nil
end
```

### Conditional Error Handling

```ruby
def delete_board_safely(client, board_id)
  begin
    response = client.board.delete(board_id)
    puts "Board deleted successfully"
    true

  rescue Monday::ResourceNotFoundError => e
    puts "Board not found (already deleted?)"
    true  # Not an error - board is gone

  rescue Monday::AuthorizationError => e
    puts "Not authorized to delete board"
    false

  rescue Monday::Error => e
    puts "Failed to delete board: #{e.message}"
    false
  end
end
```

### Extract Error Information

```ruby
begin
  response = client.column.change_simple_value(
    args: {
      board_id: 123,
      item_id: 456,
      column_id: "status",
      value: "Done"
    }
  )

rescue Monday::InvalidRequestError => e
  puts "Error code: #{e.code}"
  # => "InvalidBoardIdException"

  puts "Error message: #{e.message}"
  # => "The board does not exist..."

  puts "HTTP status: #{e.response.status}"
  # => 200

  puts "Error data: #{e.error_data.inspect}"
  # => {"board_id" => 123}

  # Check what's invalid
  if e.error_data["board_id"]
    puts "Invalid board ID: #{e.error_data["board_id"]}"
  elsif e.error_data["item_id"]
    puts "Invalid item ID: #{e.error_data["item_id"]}"
  elsif e.error_data["column_id"]
    puts "Invalid column ID: #{e.error_data["column_id"]}"
  end
end
```

### Fallback Values

```ruby
def get_board_name(client, board_id)
  response = client.board.query(
    args: {ids: [board_id]},
    select: ["id", "name"]
  )

  response.body.dig("data", "boards", 0, "name")

rescue Monday::ResourceNotFoundError
  "Board not found"

rescue Monday::AuthorizationError
  "Access denied"

rescue Monday::Error => e
  "Error: #{e.message}"
end
```

## Best Practices

1. **Rescue Specific Errors**: Catch specific error classes rather than the base `Monday::Error`
2. **Use error_data**: Access `error_data` for context-specific information (invalid IDs, etc.)
3. **Check response.success?**: For non-critical paths, check success status instead of rescuing
4. **Retry Appropriately**: Always retry `RateLimitError`, consider retrying `InternalServerError`
5. **Log Errors**: Log error details for debugging and monitoring
6. **Re-raise When Needed**: Re-raise errors you can't handle to avoid hiding issues
7. **Validate Input**: Validate parameters before making API calls to prevent errors
8. **Provide Fallbacks**: Return default values or partial data when appropriate
9. **User-Friendly Messages**: Convert technical errors to readable messages for end users
10. **Test Error Paths**: Write tests for error handling code

## Related Resources

- [Error Handling Guide](/guides/advanced/errors) - Comprehensive error handling guide with patterns
- [Rate Limiting Guide](/guides/advanced/rate-limiting) - Understanding and handling rate limits
- [Client](/reference/client) - Main client class that raises errors
- [Response](/reference/response) - Response object accessed via `error.response`

## External References

- [monday.com API Errors](https://developer.monday.com/api-reference/docs/errors)
- [monday.com Rate Limits](https://developer.monday.com/api-reference/docs/rate-limits)
- [GraphQL Error Handling](https://graphql.org/learn/validation/)
