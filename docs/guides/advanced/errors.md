# Error Handling

Learn how to handle errors when using the monday_ruby gem, from basic rescue blocks to advanced retry strategies.

## Understanding monday_ruby Errors

The monday_ruby gem provides a comprehensive error hierarchy that maps both HTTP status codes and monday.com API error codes to specific Ruby exception classes.

### Error Hierarchy

All errors inherit from `Monday::Error`, making it easy to catch any monday.com-related error:

```ruby
Monday::Error (base class)
├── Monday::AuthorizationError (401, 403)
├── Monday::InvalidRequestError (400)
├── Monday::ResourceNotFoundError (404)
├── Monday::InternalServerError (500)
├── Monday::RateLimitError (429)
└── Monday::ComplexityError (GraphQL complexity limit)
```

### When Errors Are Raised

Errors are raised in two scenarios:

1. **HTTP Status Codes**: Non-2xx status codes (401, 404, 500, etc.)
2. **GraphQL Error Codes**: Even when HTTP status is 200, GraphQL errors in the response trigger exceptions

```ruby
# Example: HTTP 401 raises Monday::AuthorizationError
client = Monday::Client.new(token: "invalid_token")
client.account.query # => Monday::AuthorizationError

# Example: HTTP 200 with error_code raises Monday::InvalidRequestError
client.board.query(args: {ids: [999999]}) # => Monday::InvalidRequestError
```

### Error Properties

Every error object provides access to:

```ruby
begin
  client.board.query(args: {ids: [123]})
rescue Monday::Error => e
  e.message    # Human-readable error message
  e.code       # Error code (HTTP status or error_code)
  e.response   # Full Monday::Response object
  e.error_data # Additional error metadata (hash)
end
```

## Basic Error Handling

### Check Response Success

The safest approach is to check `response.success?` before accessing data:

```ruby
response = client.board.query(args: {ids: [123]}, select: ["id", "name"])

if response.success?
  boards = response.body["data"]["boards"]
  puts "Found #{boards.length} boards"
else
  puts "Request failed: #{response.body["error_message"]}"
end
```

### Rescue Specific Errors

Catch specific error types to handle different scenarios:

```ruby
begin
  response = client.item.create(
    args: {
      board_id: 123,
      item_name: "New Task"
    },
    select: ["id", "name"]
  )

  item = response.body["data"]["create_item"]
  puts "Created item: #{item["name"]}"

rescue Monday::AuthorizationError => e
  puts "Authentication failed. Check your API token."

rescue Monday::InvalidRequestError => e
  puts "Invalid request: #{e.message}"
  # Check error_data for specifics
  puts "Error details: #{e.error_data}"

rescue Monday::Error => e
  puts "Unexpected error: #{e.message}"
end
```

### Access Error Messages

Extract error information from the exception:

```ruby
begin
  client.folder.delete(args: {folder_id: "invalid_id"})
rescue Monday::Error => e
  puts "Error code: #{e.code}"
  puts "Error message: #{e.message}"

  # Access the raw response
  puts "HTTP status: #{e.response.status}"
  puts "Response body: #{e.response.body}"

  # Get additional error data
  if e.error_data.any?
    puts "Error data: #{e.error_data.inspect}"
  end
end
```

## Handle Common Errors

### AuthorizationError (401, 403)

Raised when authentication fails or you lack permissions.

**Common causes:**
- Invalid API token
- Token doesn't have required permissions
- Token has been revoked

```ruby
begin
  client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])
  response = client.account.query(select: ["id", "name"])

rescue Monday::AuthorizationError => e
  puts "Authorization failed: #{e.message}"
  puts "Please check your API token in the monday.com Developer Portal"
  puts "Make sure the token has the required scopes"

  # Log for debugging
  logger.error("Monday.com auth error: #{e.message}")

  # Return nil or default value
  nil
end
```

**Real error example:**
```json
{
  "errors": ["Not Authenticated"],
  "status": 401
}
```

### InvalidRequestError (400)

Raised when request parameters are invalid.

**Common causes:**
- Invalid board/item/column IDs
- Malformed GraphQL query
- Invalid column values
- Missing required parameters

```ruby
begin
  response = client.column.change_simple_value(
    args: {
      board_id: 123,  # Invalid board ID
      item_id: 456,
      column_id: "status",
      value: "Working on it"
    },
    select: ["id", "name"]
  )

rescue Monday::InvalidRequestError => e
  case e.error_data
  when ->(data) { data["board_id"] }
    puts "Board not found: #{e.error_data["board_id"]}"
    puts "Please verify the board ID and try again"

  when ->(data) { data["item_id"] }
    puts "Item not found: #{e.error_data["item_id"]}"

  when ->(data) { data["column_id"] }
    puts "Invalid column: #{e.error_data["column_id"]}"

  else
    puts "Invalid request: #{e.message}"
  end
end
```

**Real error example:**
```json
{
  "error_message": "The board does not exist. Please check your board ID and try again",
  "error_code": "InvalidBoardIdException",
  "error_data": {"board_id": 123},
  "status_code": 200
}
```

### ResourceNotFoundError (404)

Raised when a resource doesn't exist.

```ruby
def delete_folder_safely(client, folder_id)
  begin
    response = client.folder.delete(args: {folder_id: folder_id})
    puts "Folder deleted successfully"

  rescue Monday::ResourceNotFoundError => e
    puts "Folder not found: #{e.error_data["folder_id"]}"
    puts "It may have already been deleted"
    # Don't raise - this is acceptable

  rescue Monday::Error => e
    puts "Failed to delete folder: #{e.message}"
    raise # Re-raise for unexpected errors
  end
end
```

**Real error example:**
```json
{
  "error_message": "The folder does not exist. Please check your folder ID and try again",
  "error_code": "InvalidFolderIdException",
  "error_data": {"folder_id": 0},
  "status_code": 200
}
```

### RateLimitError (429)

Raised when you exceed monday.com's rate limits.

**Rate limits:**
- Queries: Complexity-based (max 10,000,000 per minute)
- Mutations: 60 requests per minute per user

```ruby
def query_with_rate_limit_handling(client)
  begin
    response = client.board.query(
      args: {limit: 100},
      select: ["id", "name", "items"]
    )

  rescue Monday::RateLimitError => e
    puts "Rate limit exceeded: #{e.message}"

    # Wait before retrying
    sleep 60

    puts "Retrying after rate limit cooldown..."
    retry
  end
end
```

### InternalServerError (500)

Raised when monday.com's servers encounter an error.

**Common causes:**
- monday.com service issues
- Invalid item/board ID causing server error
- Temporary API outages

```ruby
def create_update_with_server_error_handling(client, item_id, body)
  max_retries = 3
  retry_count = 0

  begin
    response = client.update.create(
      args: {item_id: item_id, body: body},
      select: ["id", "body", "created_at"]
    )

    response.body["data"]["create_update"]

  rescue Monday::InternalServerError => e
    retry_count += 1

    if retry_count < max_retries
      puts "Server error (attempt #{retry_count}/#{max_retries}): #{e.message}"
      sleep 2 ** retry_count # Exponential backoff
      retry
    else
      puts "Server error persists after #{max_retries} attempts"
      raise
    end
  end
end
```

**Real error example:**
```json
{
  "status_code": 500,
  "error_message": "Internal server error",
  "error_code": "INTERNAL_SERVER_ERROR"
}
```

## Advanced Error Handling

### Retry Logic with Exponential Backoff

Implement smart retry logic for transient errors:

```ruby
class MondayRetryHandler
  MAX_RETRIES = 3
  BASE_DELAY = 1 # seconds

  def self.with_retry(&block)
    retry_count = 0

    begin
      yield

    rescue Monday::RateLimitError => e
      # Always wait for rate limits
      puts "Rate limited. Waiting 60 seconds..."
      sleep 60
      retry

    rescue Monday::InternalServerError, Monday::Error => e
      retry_count += 1

      if retry_count < MAX_RETRIES
        delay = BASE_DELAY * (2 ** (retry_count - 1))
        puts "Error: #{e.message}. Retrying in #{delay}s (attempt #{retry_count}/#{MAX_RETRIES})"
        sleep delay
        retry
      else
        puts "Failed after #{MAX_RETRIES} attempts"
        raise
      end
    end
  end
end

# Usage
MondayRetryHandler.with_retry do
  client.item.create(
    args: {board_id: 123, item_name: "New Task"},
    select: ["id", "name"]
  )
end
```

### Rescue with Fallbacks

Provide fallback values when errors occur:

```ruby
def get_board_or_default(client, board_id)
  response = client.board.query(
    args: {ids: [board_id]},
    select: ["id", "name", "description"]
  )

  response.body["data"]["boards"].first

rescue Monday::ResourceNotFoundError
  # Return a default board structure
  {
    "id" => nil,
    "name" => "Board not found",
    "description" => ""
  }

rescue Monday::AuthorizationError
  # Return nil for auth errors
  nil

rescue Monday::Error => e
  # Log unexpected errors
  puts "Unexpected error: #{e.message}"
  nil
end
```

### Error Logging

Integrate with your logging system:

```ruby
require 'logger'

class MondayClient
  def initialize(token:, logger: Logger.new(STDOUT))
    @client = Monday::Client.new(token: token)
    @logger = logger
  end

  def safe_query(resource, method, args)
    response = @client.public_send(resource).public_send(method, **args)

    if response.success?
      @logger.info("monday.com API success: #{resource}.#{method}")
      response.body["data"]
    else
      @logger.error("monday.com API error: #{response.body["error_message"]}")
      nil
    end

  rescue Monday::AuthorizationError => e
    @logger.error("monday.com auth error: #{e.message}")
    raise

  rescue Monday::RateLimitError => e
    @logger.warn("monday.com rate limit: #{e.message}")
    raise

  rescue Monday::Error => e
    @logger.error("monday.com error: #{e.class} - #{e.message}")
    @logger.error("Error data: #{e.error_data.inspect}") if e.error_data.any?
    raise
  end
end

# Usage
client = MondayClient.new(
  token: ENV["MONDAY_TOKEN"],
  logger: Logger.new("monday.log")
)

client.safe_query(:board, :query, {args: {ids: [123]}, select: ["id", "name"]})
```

### Validation Before API Calls

Prevent errors by validating input:

```ruby
module MondayValidation
  class ValidationError < StandardError; end

  def self.validate_board_id!(board_id)
    raise ValidationError, "board_id must be an integer" unless board_id.is_a?(Integer)
    raise ValidationError, "board_id must be positive" unless board_id > 0
  end

  def self.validate_item_name!(item_name)
    raise ValidationError, "item_name cannot be empty" if item_name.to_s.strip.empty?
    raise ValidationError, "item_name too long (max 255 chars)" if item_name.length > 255
  end

  def self.validate_column_value!(column_id, value)
    raise ValidationError, "column_id cannot be empty" if column_id.to_s.strip.empty?
    raise ValidationError, "value cannot be nil" if value.nil?
  end
end

# Usage
def create_item_safely(client, board_id, item_name)
  # Validate before making API call
  MondayValidation.validate_board_id!(board_id)
  MondayValidation.validate_item_name!(item_name)

  client.item.create(
    args: {board_id: board_id, item_name: item_name},
    select: ["id", "name"]
  )

rescue MondayValidation::ValidationError => e
  puts "Validation error: #{e.message}"
  nil

rescue Monday::Error => e
  puts "API error: #{e.message}"
  nil
end
```

## Error Handling Patterns

### Safe Wrapper for API Calls

Create a reusable wrapper for consistent error handling:

```ruby
class SafeMondayClient
  def initialize(client)
    @client = client
  end

  def safe_call(resource, method, args = {})
    response = @client.public_send(resource).public_send(method, **args)

    yield(response.body["data"]) if block_given? && response.success?

    response.success? ? response.body["data"] : nil

  rescue Monday::AuthorizationError => e
    handle_auth_error(e)
    nil

  rescue Monday::ResourceNotFoundError => e
    handle_not_found_error(e)
    nil

  rescue Monday::RateLimitError => e
    handle_rate_limit_error(e)
    sleep 60
    retry

  rescue Monday::Error => e
    handle_generic_error(e)
    nil
  end

  private

  def handle_auth_error(error)
    puts "Authentication failed. Please check your API token."
    # Send alert, log to monitoring service, etc.
  end

  def handle_not_found_error(error)
    puts "Resource not found: #{error.message}"
  end

  def handle_rate_limit_error(error)
    puts "Rate limit exceeded. Retrying in 60 seconds..."
  end

  def handle_generic_error(error)
    puts "Error: #{error.message}"
    # Log to error tracking service (Sentry, Rollbar, etc.)
  end
end

# Usage
client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])
safe_client = SafeMondayClient.new(client)

data = safe_client.safe_call(:board, :query, {
  args: {ids: [123]},
  select: ["id", "name"]
})

if data
  boards = data["boards"]
  puts "Found #{boards.length} boards"
else
  puts "Failed to retrieve boards"
end
```

### Graceful Degradation

Continue operation even when some calls fail:

```ruby
def get_dashboard_data(client)
  dashboard = {
    boards: [],
    workspaces: [],
    account: nil
  }

  # Try to get boards
  begin
    response = client.board.query(args: {limit: 10}, select: ["id", "name"])
    dashboard[:boards] = response.body["data"]["boards"] if response.success?
  rescue Monday::Error => e
    puts "Failed to load boards: #{e.message}"
    # Continue anyway - boards will be empty array
  end

  # Try to get workspaces
  begin
    response = client.workspace.query(select: ["id", "name"])
    dashboard[:workspaces] = response.body["data"]["workspaces"] if response.success?
  rescue Monday::Error => e
    puts "Failed to load workspaces: #{e.message}"
    # Continue anyway
  end

  # Try to get account
  begin
    response = client.account.query(select: ["id", "name"])
    dashboard[:account] = response.body["data"]["account"] if response.success?
  rescue Monday::Error => e
    puts "Failed to load account: #{e.message}"
    # Continue anyway
  end

  # Return partial data - better than nothing
  dashboard
end

# Usage
dashboard = get_dashboard_data(client)
puts "Loaded #{dashboard[:boards].length} boards"
puts "Loaded #{dashboard[:workspaces].length} workspaces"
puts dashboard[:account] ? "Account: #{dashboard[:account]["name"]}" : "Account unavailable"
```

### User-Friendly Error Messages

Convert technical errors to user-friendly messages:

```ruby
module MondayErrorMessages
  def self.humanize(error)
    case error
    when Monday::AuthorizationError
      "Unable to connect to monday.com. Please check your access token."

    when Monday::ResourceNotFoundError
      if error.error_data["board_id"]
        "The board you're looking for doesn't exist or has been deleted."
      elsif error.error_data["item_id"]
        "The item you're looking for doesn't exist or has been deleted."
      elsif error.error_data["folder_id"]
        "The folder you're looking for doesn't exist or has been deleted."
      else
        "The resource you're looking for could not be found."
      end

    when Monday::RateLimitError
      "You're making too many requests. Please wait a minute and try again."

    when Monday::InternalServerError
      "monday.com is experiencing technical difficulties. Please try again later."

    when Monday::InvalidRequestError
      case error.message
      when /InvalidBoardIdException/
        "Invalid board. Please check the board ID and try again."
      when /InvalidItemIdException/
        "Invalid item. Please check the item ID and try again."
      when /InvalidColumnIdException/
        "Invalid column. Please check the column ID and try again."
      when /ColumnValueException/
        "Invalid column value. Please check the format and try again."
      else
        "Invalid request. Please check your input and try again."
      end

    else
      "An unexpected error occurred. Please try again or contact support."
    end
  end
end

# Usage in a web application
begin
  response = client.item.create(
    args: {board_id: params[:board_id], item_name: params[:item_name]},
    select: ["id", "name"]
  )

  flash[:success] = "Item created successfully!"
  redirect_to board_path(params[:board_id])

rescue Monday::Error => e
  flash[:error] = MondayErrorMessages.humanize(e)
  redirect_to :back
end
```

## GraphQL Errors

### Access GraphQL Error Details

monday.com returns GraphQL errors with detailed information:

```ruby
begin
  response = client.account.query(select: ["id", "invalid_field"])
rescue Monday::Error => e
  # Access the full error array
  if e.response.body["errors"]
    e.response.body["errors"].each do |error|
      puts "Error: #{error["message"]}"
      puts "Location: line #{error["locations"]&.first&.dig("line")}"
      puts "Path: #{error["path"]&.join(" > ")}"
      puts "Code: #{error.dig("extensions", "code")}"
    end
  end
end
```

**Real GraphQL error structure:**
```json
{
  "errors": [
    {
      "message": "Field 'invalid_field' doesn't exist on type 'Account'",
      "locations": [{"line": 1, "column": 10}],
      "path": ["account"],
      "extensions": {
        "code": "undefinedField",
        "typeName": "Account",
        "fieldName": "invalid_field"
      }
    }
  ]
}
```

### Parse GraphQL Error Messages

Extract meaningful information from GraphQL errors:

```ruby
def parse_graphql_errors(response_body)
  return [] unless response_body["errors"]

  response_body["errors"].map do |error|
    {
      message: error["message"],
      field: error.dig("extensions", "fieldName"),
      type: error.dig("extensions", "typeName"),
      code: error.dig("extensions", "code"),
      path: error["path"]&.join("."),
      line: error.dig("locations", 0, "line")
    }
  end
end

# Usage
begin
  response = client.board.query(
    args: {ids: [123]},
    select: ["id", "invalid_field"]
  )
rescue Monday::Error => e
  errors = parse_graphql_errors(e.response.body)

  errors.each do |error|
    puts "GraphQL Error:"
    puts "  Message: #{error[:message]}"
    puts "  Field: #{error[:field]}" if error[:field]
    puts "  Type: #{error[:type]}" if error[:type]
    puts "  Code: #{error[:code]}" if error[:code]
  end
end
```

### Handle Field-Specific Errors

Catch errors for specific fields:

```ruby
def query_board_with_fallback_fields(client, board_id)
  # Try querying with all desired fields
  fields = ["id", "name", "description", "items_count", "board_kind"]

  begin
    response = client.board.query(
      args: {ids: [board_id]},
      select: fields
    )

    return response.body["data"]["boards"].first if response.success?

  rescue Monday::Error => e
    if e.response.body["errors"]
      # Find which fields are invalid
      invalid_fields = e.response.body["errors"].map do |error|
        error.dig("extensions", "fieldName")
      end.compact

      # Retry with only valid fields
      valid_fields = fields - invalid_fields

      if valid_fields.any?
        puts "Retrying with valid fields: #{valid_fields.join(", ")}"

        response = client.board.query(
          args: {ids: [board_id]},
          select: valid_fields
        )

        return response.body["data"]["boards"].first if response.success?
      end
    end

    raise # Re-raise if we can't recover
  end
end
```

## Best Practices

1. **Always handle errors**: Never assume API calls will succeed
2. **Be specific**: Rescue specific error classes rather than catching all errors
3. **Validate input**: Check parameters before making API calls
4. **Log errors**: Keep track of errors for debugging and monitoring
5. **Retry wisely**: Implement exponential backoff for transient errors
6. **Fail gracefully**: Provide fallback values or partial data when possible
7. **User-friendly messages**: Convert technical errors to readable messages
8. **Monitor rate limits**: Track your API usage to avoid rate limit errors
9. **Check error_data**: Use the error_data hash for context-specific handling
10. **Test error paths**: Write tests for your error handling code

## Related Resources

- [monday.com API Rate Limits](https://developer.monday.com/api-reference/docs/rate-limits)
- [GraphQL Error Handling](https://developer.monday.com/api-reference/docs/errors)
- [Authentication Guide](../authentication.md)
