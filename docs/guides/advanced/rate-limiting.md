# Handle Rate Limits

Manage monday.com API rate limits and complexity budgets to prevent errors and optimize API usage.

## Prerequisites

- [Installed and configured](/guides/installation) monday_ruby
- [Set up authentication](/guides/authentication) with your API token
- Understanding of [basic requests](/guides/first-request)

## Understanding Rate Limits

monday.com uses a **complexity budget system** to manage API load. Every query consumes complexity points based on the data requested.

### Complexity Limits by Plan

**Per-minute limits** (sliding 60-second window):

| Token Type | Plan | Complexity Budget |
|------------|------|-------------------|
| Personal API Token | Free/Trial/NGO | 1,000,000 points |
| Personal API Token | Paid Plans | 10,000,000 points |
| App Token | All Plans | 5,000,000 (read) + 5,000,000 (write) |
| API Playground | Free/Trial | 1,000,000 points |
| API Playground | Paid Plans | 5,000,000 points |

**Per-query limit**: 5,000,000 complexity points maximum

### Daily Call Limits

Daily limits reset at **midnight UTC**:

| Plan | Daily Calls |
|------|-------------|
| Free/Trial | 200 |
| Standard/Basic | 1,000 |
| Pro | 10,000 (soft limit) |
| Enterprise | 25,000 (soft limit) |

**Note**: Rate-limited requests count as 0.1 calls; high-complexity queries count as 1+ calls.

### Common Query Complexity Costs

Approximate complexity points per operation:

- **Simple query** (boards list): ~500-1,000 points
- **Create item**: ~10,000 points
- **Nested query** (boards with items): ~5,000-50,000 points
- **Bulk operations**: Varies based on batch size

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Estimate Before Creating</span>
When creating items in bulk, avoid creating more than 10-20 items in rapid succession to prevent hitting the complexity limit.
:::

## Monitor Complexity Usage

Check your complexity budget using the complexity query:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])

# Query with complexity field to monitor usage
query = <<~GRAPHQL
  query {
    complexity {
      before
      after
      query
      reset_in_x_seconds
    }
    boards(limit: 1) {
      id
      name
    }
  }
GRAPHQL

response = client.make_request(query)

if response.success?
  complexity = response.body.dig("data", "complexity")

  puts "Complexity Budget Status:"
  puts "  Before query: #{complexity['before']} points"
  puts "  Query cost: #{complexity['query']} points"
  puts "  After query: #{complexity['after']} points"
  puts "  Resets in: #{complexity['reset_in_x_seconds']} seconds"
end
```

**Example output:**
```
Complexity Budget Status:
  Before query: 10000000 points
  Query cost: 883 points
  After query: 9999117 points
  Resets in: 45 seconds
```

## Handle Rate Limit Errors

The gem raises `Monday::RateLimitError` when rate limits are exceeded:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])

begin
  response = client.board.query(
    args: { limit: 100 },
    select: ["id", "name", { items: ["id", "name", "column_values"] }]
  )

  boards = response.body.dig("data", "boards")
  puts "Successfully retrieved #{boards.length} boards"

rescue Monday::RateLimitError => e
  puts "Rate limit exceeded!"
  puts "Error: #{e.message}"
  puts "Error code: #{e.code}"

  # Check for retry timing in error data
  retry_seconds = e.error_data["retry_in_seconds"]

  if retry_seconds
    puts "Retry after #{retry_seconds} seconds"
  else
    puts "Wait 60 seconds before retrying"
  end
end
```

### Error Response Structure

Rate limit errors include helpful metadata:

```ruby
begin
  # Expensive query that exceeds limit
  response = client.item.create(
    args: { board_id: 1234567890, item_name: "Test" }
  )
rescue Monday::RateLimitError => e
  # Access error details
  puts "Message: #{e.message}"
  # => "ComplexityException" or "Complexity budget exhausted"

  puts "Code: #{e.code}"
  # => 429

  puts "Error data: #{e.error_data}"
  # => {"retry_in_seconds"=>30} (if available)
end
```

## Retry with Exponential Backoff

Implement automatic retry logic with progressive delays:

```ruby
require "monday_ruby"

def make_request_with_retry(client, max_retries: 3)
  retries = 0
  base_delay = 2 # seconds

  begin
    response = yield(client)
    return response

  rescue Monday::RateLimitError => e
    retries += 1

    if retries <= max_retries
      # Calculate exponential backoff delay
      delay = base_delay * (2 ** (retries - 1))

      # Use retry_in_seconds from API if available
      if e.error_data["retry_in_seconds"]
        delay = e.error_data["retry_in_seconds"]
      end

      puts "Rate limit hit. Retry #{retries}/#{max_retries} in #{delay}s..."
      sleep(delay)
      retry
    else
      puts "Max retries exceeded. Giving up."
      raise
    end
  end
end

# Usage
client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])

response = make_request_with_retry(client, max_retries: 3) do |c|
  c.board.query(
    args: { limit: 50 },
    select: ["id", "name", { items: ["id", "name"] }]
  )
end

if response.success?
  boards = response.body.dig("data", "boards")
  puts "Retrieved #{boards.length} boards"
end
```

### Advanced Retry with Jitter

Add random jitter to prevent thundering herd:

```ruby
require "monday_ruby"

def exponential_backoff_with_jitter(retries, base_delay: 2, max_delay: 60)
  # Calculate exponential backoff
  delay = [base_delay * (2 ** (retries - 1)), max_delay].min

  # Add random jitter (±25%)
  jitter = delay * 0.25 * (rand - 0.5) * 2
  delay + jitter
end

def robust_api_call(client, max_retries: 5)
  retries = 0

  begin
    yield(client)

  rescue Monday::RateLimitError => e
    retries += 1

    if retries <= max_retries
      delay = exponential_backoff_with_jitter(retries)

      # Prefer API-provided retry timing
      if e.error_data["retry_in_seconds"]
        delay = e.error_data["retry_in_seconds"]
      end

      puts "[Retry #{retries}/#{max_retries}] Waiting #{delay.round(2)}s..."
      sleep(delay)
      retry
    else
      raise
    end
  end
end

# Usage
client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])

begin
  response = robust_api_call(client, max_retries: 5) do |c|
    c.item.create(
      args: {
        board_id: 1234567890,
        item_name: "High Priority Task"
      },
      select: ["id", "name"]
    )
  end

  item = response.body.dig("data", "create_item")
  puts "Created item: #{item['name']} (ID: #{item['id']})"

rescue Monday::RateLimitError
  puts "Failed after all retries due to rate limiting"
end
```

## Rate Limiting Strategies

### Add Delays Between Requests

Prevent rate limit errors by spacing out API calls:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])

board_ids = [1234567890, 2345678901, 3456789012, 4567890123]
boards_data = []

board_ids.each_with_index do |board_id, index|
  # Add delay after each request (except the first)
  sleep(0.5) if index > 0

  response = client.board.query(
    args: { ids: [board_id] },
    select: ["id", "name", { items: ["id", "name"] }]
  )

  if response.success?
    board = response.body.dig("data", "boards", 0)
    boards_data << board
    puts "Fetched board: #{board['name']}"
  end
end

puts "Total boards fetched: #{boards_data.length}"
```

### Batch Operations Efficiently

Group operations to reduce API calls:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])

# Instead of querying boards one by one:
# ❌ Multiple requests (inefficient)
board_ids = [1234567890, 2345678901, 3456789012]
boards = board_ids.map do |id|
  sleep(0.5) # Still need delays to avoid rate limits
  response = client.board.query(args: { ids: [id] })
  response.body.dig("data", "boards", 0)
end

# ✅ Single request (efficient)
response = client.board.query(
  args: { ids: board_ids },
  select: ["id", "name", "description"]
)

boards = response.body.dig("data", "boards")
puts "Fetched #{boards.length} boards in one request"
```

### Use Pagination to Control Load

Request data in smaller chunks:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])

def fetch_items_paginated(client, board_id, page_size: 25)
  all_items = []
  page = 1

  loop do
    response = client.board.query(
      args: { ids: [board_id] },
      select: [
        "id",
        "name",
        {
          items_page: {
            args: { limit: page_size, query_params: { page: page } },
            select: ["cursor", { items: ["id", "name"] }]
          }
        }
      ]
    )

    board = response.body.dig("data", "boards", 0)
    items_page = board.dig("items_page")
    items = items_page["items"]

    all_items.concat(items)
    puts "Fetched page #{page}: #{items.length} items"

    # Stop if we got fewer items than page size
    break if items.length < page_size

    page += 1

    # Add delay between pages
    sleep(0.5)
  end

  all_items
end

# Usage
items = fetch_items_paginated(client, 1234567890, page_size: 50)
puts "Total items fetched: #{items.length}"
```

### Reduce Query Complexity

Request only essential fields:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])

# ❌ High complexity (requests everything)
response = client.board.query(
  args: { ids: [1234567890] },
  select: [
    "id", "name", "description", "state", "board_folder_id",
    {
      items: [
        "id", "name", "state", "created_at", "updated_at",
        { column_values: ["id", "text", "value", "type"] },
        { updates: ["id", "body", "created_at"] }
      ]
    },
    { groups: ["id", "title", "color"] },
    { columns: ["id", "title", "type", "settings_str"] }
  ]
)

# ✅ Low complexity (requests only what's needed)
response = client.board.query(
  args: { ids: [1234567890] },
  select: [
    "id",
    "name",
    { items: ["id", "name"] }
  ]
)

if response.success?
  board = response.body.dig("data", "boards", 0)
  puts "Board: #{board['name']}, Items: #{board['items'].length}"
end
```

## Production-Ready Rate Limiter

Create a reusable rate limiter class:

```ruby
require "monday_ruby"

class MondayRateLimiter
  def initialize(client, requests_per_minute: 60)
    @client = client
    @requests_per_minute = requests_per_minute
    @min_delay = 60.0 / requests_per_minute
    @last_request_time = nil
  end

  def execute(max_retries: 3, &block)
    enforce_rate_limit

    retries = 0

    begin
      response = block.call(@client)
      @last_request_time = Time.now
      response

    rescue Monday::RateLimitError => e
      retries += 1

      if retries <= max_retries
        delay = calculate_backoff_delay(retries, e)
        puts "[Rate Limit] Retry #{retries}/#{max_retries} in #{delay.round(2)}s"
        sleep(delay)
        retry
      else
        raise
      end
    end
  end

  private

  def enforce_rate_limit
    return unless @last_request_time

    elapsed = Time.now - @last_request_time
    sleep_time = @min_delay - elapsed

    sleep(sleep_time) if sleep_time > 0
  end

  def calculate_backoff_delay(retries, error)
    # Use API-provided retry timing if available
    return error.error_data["retry_in_seconds"] if error.error_data["retry_in_seconds"]

    # Otherwise use exponential backoff
    base_delay = 2
    max_delay = 60
    delay = [base_delay * (2 ** (retries - 1)), max_delay].min

    # Add jitter
    jitter = delay * 0.25 * (rand - 0.5) * 2
    delay + jitter
  end
end

# Usage
client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])
limiter = MondayRateLimiter.new(client, requests_per_minute: 30)

# Create multiple items with rate limiting
item_names = ["Task 1", "Task 2", "Task 3", "Task 4", "Task 5"]
board_id = 1234567890

item_names.each do |item_name|
  response = limiter.execute do |c|
    c.item.create(
      args: { board_id: board_id, item_name: item_name },
      select: ["id", "name"]
    )
  end

  if response.success?
    item = response.body.dig("data", "create_item")
    puts "Created: #{item['name']}"
  end
end
```

## Queue-Based Rate Limiting

Process requests in a queue with controlled throughput:

```ruby
require "monday_ruby"
require "thread"

class MondayRequestQueue
  def initialize(client, max_requests_per_minute: 60)
    @client = client
    @queue = Queue.new
    @max_requests_per_minute = max_requests_per_minute
    @delay_between_requests = 60.0 / max_requests_per_minute
    @running = false
  end

  def start
    return if @running

    @running = true
    @worker_thread = Thread.new { process_queue }
  end

  def stop
    @running = false
    @worker_thread&.join
  end

  def enqueue(&block)
    result_queue = Queue.new
    @queue << { block: block, result: result_queue }
    result_queue.pop # Wait for result
  end

  private

  def process_queue
    while @running
      begin
        request = @queue.pop(true) # Non-blocking pop

        # Execute the request
        result = execute_with_retry(request[:block])
        request[:result] << result

        # Wait before next request
        sleep(@delay_between_requests)

      rescue ThreadError
        # Queue is empty, sleep briefly
        sleep(0.1)
      end
    end
  end

  def execute_with_retry(block, max_retries: 3)
    retries = 0

    begin
      block.call(@client)

    rescue Monday::RateLimitError => e
      retries += 1

      if retries <= max_retries
        delay = e.error_data["retry_in_seconds"] || (2 ** retries)
        sleep(delay)
        retry
      else
        raise
      end
    end
  end
end

# Usage
client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])
queue = MondayRequestQueue.new(client, max_requests_per_minute: 30)
queue.start

# Enqueue multiple requests
board_ids = [1234567890, 2345678901, 3456789012]
boards = []

board_ids.each do |board_id|
  response = queue.enqueue do |c|
    c.board.query(
      args: { ids: [board_id] },
      select: ["id", "name"]
    )
  end

  if response.success?
    board = response.body.dig("data", "boards", 0)
    boards << board
    puts "Queued and fetched: #{board['name']}"
  end
end

queue.stop
puts "Total boards: #{boards.length}"
```

## Best Practices

### 1. Monitor Your Usage

Track API calls and complexity in your application:

```ruby
require "monday_ruby"

class MondayMetrics
  attr_reader :total_requests, :total_errors, :rate_limit_errors

  def initialize(client)
    @client = client
    @total_requests = 0
    @total_errors = 0
    @rate_limit_errors = 0
  end

  def execute(&block)
    @total_requests += 1
    start_time = Time.now

    begin
      response = block.call(@client)
      duration = Time.now - start_time

      log_request(duration, response)
      response

    rescue Monday::RateLimitError => e
      @rate_limit_errors += 1
      @total_errors += 1
      log_error(e, :rate_limit)
      raise

    rescue Monday::Error => e
      @total_errors += 1
      log_error(e, :api_error)
      raise
    end
  end

  def stats
    {
      total_requests: @total_requests,
      total_errors: @total_errors,
      rate_limit_errors: @rate_limit_errors,
      success_rate: success_rate
    }
  end

  private

  def success_rate
    return 0 if @total_requests.zero?
    (((@total_requests - @total_errors).to_f / @total_requests) * 100).round(2)
  end

  def log_request(duration, response)
    puts "[REQUEST] Completed in #{duration.round(3)}s - Status: #{response.status}"
  end

  def log_error(error, type)
    puts "[ERROR:#{type}] #{error.class}: #{error.message}"
  end
end

# Usage
client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])
metrics = MondayMetrics.new(client)

# Make several requests
5.times do |i|
  begin
    response = metrics.execute do |c|
      c.board.query(args: { limit: 10 })
    end
    puts "Request #{i + 1} succeeded"
  rescue Monday::Error => e
    puts "Request #{i + 1} failed: #{e.message}"
  end

  sleep(0.5)
end

puts "\nFinal Stats:"
puts metrics.stats
```

### 2. Cache API Responses

Reduce API calls by caching responses:

```ruby
require "monday_ruby"

class MondayCache
  def initialize(client, ttl: 300)
    @client = client
    @cache = {}
    @ttl = ttl # Time to live in seconds
  end

  def get_board(board_id, select: ["id", "name"])
    cache_key = "board_#{board_id}_#{select.hash}"

    # Check cache
    if cached = get_from_cache(cache_key)
      puts "[CACHE HIT] Board #{board_id}"
      return cached
    end

    # Fetch from API
    puts "[CACHE MISS] Fetching board #{board_id}"
    response = @client.board.query(
      args: { ids: [board_id] },
      select: select
    )

    if response.success?
      board = response.body.dig("data", "boards", 0)
      set_in_cache(cache_key, board)
      board
    end
  end

  def clear_cache
    @cache.clear
  end

  private

  def get_from_cache(key)
    entry = @cache[key]
    return nil unless entry

    # Check if expired
    if Time.now - entry[:timestamp] > @ttl
      @cache.delete(key)
      return nil
    end

    entry[:data]
  end

  def set_in_cache(key, data)
    @cache[key] = {
      data: data,
      timestamp: Time.now
    }
  end
end

# Usage
client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])
cache = MondayCache.new(client, ttl: 600) # 10 minute cache

# First request - cache miss
board1 = cache.get_board(1234567890)
puts "Board: #{board1['name']}"

# Second request - cache hit (no API call)
board2 = cache.get_board(1234567890)
puts "Board: #{board2['name']}"
```

### 3. Optimize Query Depth

Avoid deeply nested queries:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])

# ❌ Deeply nested (high complexity)
response = client.board.query(
  args: { ids: [1234567890] },
  select: [
    "id", "name",
    {
      items: [
        "id", "name",
        {
          column_values: ["id", "text", "value"],
          updates: [
            "id", "body",
            { replies: ["id", "body"] }
          ]
        }
      ]
    }
  ]
)

# ✅ Shallow queries (lower complexity)
# First, get the board and items
response1 = client.board.query(
  args: { ids: [1234567890] },
  select: ["id", "name", { items: ["id", "name"] }]
)

board = response1.body.dig("data", "boards", 0)
item_ids = board["items"].map { |i| i["id"] }

# Then, get item details separately if needed
response2 = client.item.query(
  args: { ids: item_ids.take(10) }, # Process in batches
  select: ["id", "name", { column_values: ["id", "text"] }]
)
```

### 4. Use Environment-Based Limits

Configure rate limits based on environment:

```ruby
require "monday_ruby"

class MondayClientFactory
  def self.create(environment: :production)
    client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])

    config = rate_limit_config(environment)
    MondayRateLimiter.new(client, **config)
  end

  def self.rate_limit_config(environment)
    case environment
    when :production
      { requests_per_minute: 30 }  # Conservative for production
    when :development
      { requests_per_minute: 10 }  # Very conservative for dev
    when :testing
      { requests_per_minute: 5 }   # Minimal for tests
    else
      { requests_per_minute: 20 }  # Default
    end
  end
end

# Usage
limiter = MondayClientFactory.create(environment: :production)

response = limiter.execute do |c|
  c.board.query(args: { limit: 10 })
end
```

## Troubleshooting

### Rate Limit Exceeded Despite Delays

**Problem**: Still getting rate limit errors even with delays between requests.

**Solution**: Your queries may have high complexity. Reduce fields or use pagination:

```ruby
# Instead of fetching all items at once
response = client.board.query(
  args: { ids: [1234567890] },
  select: ["id", "name", { items: ["id", "name"] }]
)

# Use pagination
response = client.board.query(
  args: { ids: [1234567890] },
  select: [
    "id", "name",
    {
      items_page: {
        args: { limit: 25 },
        select: [{ items: ["id", "name"] }]
      }
    }
  ]
)
```

### Complexity Budget Exhausted

**Problem**: Getting `COMPLEXITY_BUDGET_EXHAUSTED` error.

**Solution**: Check your remaining budget before expensive operations:

```ruby
query = <<~GRAPHQL
  query {
    complexity {
      before
      reset_in_x_seconds
    }
  }
GRAPHQL

response = client.make_request(query)
complexity = response.body.dig("data", "complexity")

if complexity["before"] < 100000
  puts "Low budget. Waiting #{complexity['reset_in_x_seconds']}s..."
  sleep(complexity["reset_in_x_seconds"])
end

# Now make your request
```

### Concurrent Requests Causing Errors

**Problem**: Multiple threads/processes hitting rate limits.

**Solution**: Use a centralized queue or distributed rate limiter (Redis-based):

```ruby
require "redis"

class DistributedRateLimiter
  def initialize(client, redis_url: "redis://localhost:6379")
    @client = client
    @redis = Redis.new(url: redis_url)
    @key = "monday_api_rate_limit"
  end

  def execute(&block)
    wait_for_token

    begin
      block.call(@client)
    ensure
      # Record request timestamp
      @redis.zadd(@key, Time.now.to_i, SecureRandom.uuid)
      @redis.expire(@key, 60)
    end
  end

  private

  def wait_for_token
    loop do
      # Count requests in last 60 seconds
      now = Time.now.to_i
      count = @redis.zcount(@key, now - 60, now)

      if count < 30 # Max 30 requests per minute
        break
      else
        sleep(1)
      end
    end
  end
end
```

## Next Steps

- [Error handling guide](/guides/advanced/errors)
- [Optimize query performance](/guides/boards/query)
- [Pagination strategies](/guides/items/query)
- [monday.com API rate limits documentation](https://developer.monday.com/api-reference/docs/rate-limits)
