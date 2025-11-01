# Error Handling Best Practices

Error handling is a critical aspect of building resilient applications that integrate with external APIs. This guide explores the philosophy and patterns for effective error handling when using the monday_ruby gem.

## Error Handling Philosophy

In Ruby, exceptions are the primary mechanism for handling error conditions. The monday_ruby gem embraces this philosophy by providing a rich exception hierarchy that maps to specific API error conditions. This approach follows the principle that **errors should be specific enough to make informed decisions about recovery, but not so granular that they become burdensome to handle**.

The alternative—using status codes or error objects—would require checking return values after every API call, leading to verbose, error-prone code. Ruby's exception model allows your "happy path" code to remain clean while still providing robust error handling when needed.

## Why Specific Exception Types Matter

The monday_ruby gem provides specific exception classes for different error conditions:

```ruby
Monday::AuthorizationError   # Authentication/authorization failures
Monday::InvalidRequestError   # Malformed requests
Monday::ResourceNotFoundError # Missing resources
Monday::ComplexityError       # Query complexity exceeded
```

**Why not just catch a generic `Monday::Error`?** Specific exceptions enable different recovery strategies:

- **AuthorizationError**: Might indicate expired credentials → refresh token or prompt re-authentication
- **ComplexityError**: Query too complex → simplify query or retry with pagination
- **ResourceNotFoundError**: Item deleted → remove from local cache or skip processing
- **InvalidRequestError**: Programming error → log for debugging, don't retry

Using specific exceptions makes your intent clear and prevents accidentally catching unrelated errors.

## When to Rescue Specific Errors vs Base Classes

The decision of which exception level to catch depends on your recovery strategy:

### Catch Specific Exceptions When:

```ruby
begin
  client.item.query(ids: [item_id])
rescue Monday::ResourceNotFoundError
  # Specific recovery: remove from local database
  Item.find_by(monday_id: item_id)&.destroy
rescue Monday::AuthorizationError
  # Specific recovery: refresh credentials
  refresh_monday_token
  retry
end
```

This approach is best when **different errors require different recovery actions**.

### Catch Base Exception When:

```ruby
begin
  client.board.query(ids: [board_id])
rescue Monday::Error => e
  # Generic recovery: log and notify
  logger.error("Monday API error: #{e.message}")
  notify_monitoring_system(e)
  nil # Return nil to allow graceful degradation
end
```

This approach is best when **all API errors should be handled the same way** (logging, monitoring, graceful failure).

### Catch at Multiple Levels:

```ruby
begin
  sync_monday_data
rescue Monday::ComplexityError
  # Specific: wait and retry
  sleep(60)
  retry
rescue Monday::Error => e
  # Catch-all: log and fail gracefully
  logger.error("Sync failed: #{e.message}")
  false
end
```

This pattern handles specific cases specially while catching all other API errors generically.

## Error Recovery Patterns

### 1. Immediate Retry (Transient Errors)

Some errors are transient—temporary network issues, service hiccups. These warrant immediate retry:

```ruby
def fetch_with_retry(max_attempts: 3)
  attempts = 0
  begin
    attempts += 1
    client.board.query(ids: [board_id])
  rescue Monday::InternalServerError, Monday::ServiceUnavailableError
    retry if attempts < max_attempts
    raise
  end
end
```

**When to use**: Network timeouts, 5xx errors, temporary service issues.

**Trade-off**: Immediate retries can compound problems during outages. Use sparingly.

### 2. Exponential Backoff (Rate Limiting)

Rate limit errors should be retried with increasing delays:

```ruby
def fetch_with_backoff(max_attempts: 5)
  attempts = 0
  begin
    attempts += 1
    client.item.query(ids: item_ids)
  rescue Monday::ComplexityError => e
    wait_time = 2 ** attempts  # 2, 4, 8, 16, 32 seconds
    sleep(wait_time)
    retry if attempts < max_attempts
    raise
  end
end
```

**Why exponential**: Linear backoff (1s, 2s, 3s) doesn't reduce load enough. Exponential backoff gives the service time to recover.

**Trade-off**: Long waits can impact user experience. Consider background processing for retries.

### 3. Circuit Breaker (Cascading Failures)

When an API is consistently failing, stop making requests to prevent cascading failures:

```ruby
class MondayCircuitBreaker
  def initialize(failure_threshold: 5, timeout: 60)
    @failure_count = 0
    @failure_threshold = failure_threshold
    @timeout = timeout
    @opened_at = nil
  end

  def call
    raise CircuitOpenError if circuit_open?

    begin
      result = yield
      reset_failures
      result
    rescue Monday::Error => e
      record_failure
      raise
    end
  end

  private

  def circuit_open?
    @failure_count >= @failure_threshold &&
      (@opened_at.nil? || Time.now - @opened_at < @timeout)
  end

  def record_failure
    @failure_count += 1
    @opened_at = Time.now if @failure_count == @failure_threshold
  end

  def reset_failures
    @failure_count = 0
    @opened_at = nil
  end
end
```

**When to use**: High-traffic applications where API failures could cascade to other systems.

**Trade-off**: Adds complexity. May reject requests even when service has recovered.

### 4. Graceful Degradation

Instead of failing completely, provide reduced functionality:

```ruby
def get_board_data(board_id)
  begin
    client.board.query(ids: [board_id])
  rescue Monday::Error => e
    logger.warn("Failed to fetch live data: #{e.message}")
    # Fall back to cached data
    Rails.cache.read("board_#{board_id}")
  end
end
```

**When to use**: User-facing features where some data is better than no data.

**Trade-off**: Users get stale data. Must communicate data freshness clearly.

## Retry Strategies: When and How Many Times

**How many retries?**
- **Transient errors**: 2-3 retries (network blips are usually brief)
- **Rate limiting**: 5-7 retries (may need multiple backoff intervals)
- **Service outages**: 0-1 retries (unlikely to resolve quickly)

**When not to retry:**
- `InvalidRequestError`: The request is malformed; retrying won't help
- `AuthorizationError`: Credentials are invalid; retry only after refreshing
- `ResourceNotFoundError`: The resource doesn't exist; retrying won't create it

**Retry budgets**: Consider a total time budget rather than retry count:

```ruby
def fetch_with_budget(timeout: 30)
  deadline = Time.now + timeout
  attempts = 0

  begin
    attempts += 1
    client.board.query(ids: [board_id])
  rescue Monday::ComplexityError
    wait_time = 2 ** attempts
    raise if Time.now + wait_time > deadline
    sleep(wait_time)
    retry
  end
end
```

## Logging Errors for Debugging and Monitoring

Effective logging balances detail with signal-to-noise ratio.

### What to Log

**Always log:**
- Exception class and message
- Request details (endpoint, parameters—except secrets)
- Context (user ID, board ID, operation being performed)
- Timestamp and correlation ID

```ruby
begin
  client.item.create(board_id: board_id, item_name: name)
rescue Monday::Error => e
  logger.error({
    error_class: e.class.name,
    error_message: e.message,
    operation: 'create_item',
    board_id: board_id,
    item_name: name,
    user_id: current_user.id,
    correlation_id: request_id
  }.to_json)
  raise
end
```

**Don't log:**
- API tokens or credentials
- Sensitive user data (unless required for compliance)
- Full response bodies (unless debugging a specific issue)

### Log Levels

- **ERROR**: Unexpected failures that impact functionality
- **WARN**: Handled errors (graceful degradation, retries that succeed)
- **INFO**: Normal API errors that are part of business logic (e.g., validation failures)
- **DEBUG**: Full request/response details (disable in production)

```ruby
rescue Monday::ResourceNotFoundError => e
  logger.info("Item not found, skipping: #{item_id}")  # Expected condition
  nil
rescue Monday::InternalServerError => e
  logger.error("Monday API error: #{e.message}")  # Unexpected failure
  raise
```

## User-Facing vs Internal Error Messages

Exception messages serve two audiences:

### Internal Messages (for developers/logs)

Include technical details:
```ruby
"Failed to create item: ComplexityError - Query complexity exceeds limit (60/58).
Reduce query fields or implement pagination."
```

### User-Facing Messages (for end users)

Be generic and actionable:
```ruby
begin
  client.item.create(...)
rescue Monday::ComplexityError
  flash[:error] = "The operation is too complex. Please try creating fewer items at once."
rescue Monday::Error
  flash[:error] = "We couldn't complete this action. Please try again later."
end
```

**Why separate them?**
- Users don't need technical details
- Exposing internal errors can be a security risk
- User messages should suggest solutions, not explain implementation

## Graceful Degradation Patterns

Graceful degradation means providing partial functionality when full functionality fails.

### Pattern 1: Cache Fallback

```ruby
def get_board_items(board_id)
  begin
    items = client.item.query_by_board(board_id: board_id)
    Rails.cache.write("board_items_#{board_id}", items, expires_in: 1.hour)
    items
  rescue Monday::Error => e
    logger.warn("API failed, using cache: #{e.message}")
    Rails.cache.read("board_items_#{board_id}") || []
  end
end
```

### Pattern 2: Feature Toggle

```ruby
def sync_monday_data
  client.board.query(...)
rescue Monday::Error => e
  logger.error("Sync failed: #{e.message}")
  disable_monday_sync_feature!
  notify_admins
end
```

### Pattern 3: Partial Success

```ruby
def sync_multiple_boards(board_ids)
  results = { success: [], failed: [] }

  board_ids.each do |board_id|
    begin
      sync_board(board_id)
      results[:success] << board_id
    rescue Monday::Error => e
      logger.error("Board #{board_id} sync failed: #{e.message}")
      results[:failed] << board_id
    end
  end

  results
end
```

**Trade-offs**: Users may not notice degraded functionality, leading to confusion. Always communicate what's working and what's not.

## Transaction-Like Error Handling

APIs don't support transactions like databases, but you can implement transaction-like patterns:

### Pattern 1: Compensation (Undo on Error)

```ruby
def create_board_with_items(board_name, items)
  board = nil

  begin
    board = client.board.create(board_name: board_name).dig('data', 'create_board')

    items.each do |item|
      client.item.create(board_id: board['id'], item_name: item['name'])
    end

    board
  rescue Monday::Error => e
    # Compensate: delete the board if item creation failed
    client.board.delete(board_id: board['id']) if board
    raise
  end
end
```

### Pattern 2: All-or-Nothing (Validate First)

```ruby
def bulk_update_items(updates)
  # Validate all updates first
  updates.each do |update|
    validate_update!(update)
  end

  # If validation passes, perform updates
  updates.map do |update|
    client.item.update(item_id: update[:id], column_values: update[:values])
  end
rescue Monday::Error => e
  logger.error("Bulk update failed, no changes made: #{e.message}")
  raise
end
```

**Limitation**: Between validation and execution, state can change. True atomicity isn't possible with APIs.

## Testing Error Scenarios

Error handling code is only as good as its tests.

### Test Each Error Type

```ruby
RSpec.describe 'error handling' do
  it 'retries on complexity errors' do
    allow(client).to receive(:make_request)
      .and_raise(Monday::ComplexityError)
      .exactly(3).times
      .and_return(mock_response)

    result = fetch_with_retry
    expect(result).to eq(mock_response)
  end

  it 'does not retry on invalid request errors' do
    allow(client).to receive(:make_request)
      .and_raise(Monday::InvalidRequestError)

    expect { fetch_with_retry }.to raise_error(Monday::InvalidRequestError)
  end
end
```

### Test Retry Logic

```ruby
it 'implements exponential backoff' do
  allow(client).to receive(:make_request)
    .and_raise(Monday::ComplexityError)

  expect(self).to receive(:sleep).with(2)
  expect(self).to receive(:sleep).with(4)
  expect(self).to receive(:sleep).with(8)

  expect { fetch_with_backoff(max_attempts: 4) }
    .to raise_error(Monday::ComplexityError)
end
```

### Test Graceful Degradation

```ruby
it 'falls back to cache on error' do
  allow(client).to receive(:make_request)
    .and_raise(Monday::InternalServerError)

  Rails.cache.write('board_123', cached_data)

  result = get_board_data(123)
  expect(result).to eq(cached_data)
end
```

## Key Takeaways

1. **Be specific**: Use specific exception types to enable targeted recovery
2. **Retry wisely**: Use exponential backoff for rate limits, limited retries for transient errors
3. **Fail gracefully**: Provide reduced functionality when possible
4. **Log thoughtfully**: Include context for debugging, but protect sensitive data
5. **Separate concerns**: Internal errors ≠ user-facing messages
6. **Test thoroughly**: Error handling code needs tests too
7. **Monitor**: Track error rates to identify patterns and systemic issues

Error handling is not just about preventing crashes—it's about creating resilient systems that degrade gracefully and recover automatically when possible.
