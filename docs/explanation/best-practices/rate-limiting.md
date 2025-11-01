# Rate Limiting Best Practices

Rate limiting is a fundamental aspect of working with any API. Understanding why rate limits exist, how they work, and how to work effectively within them is crucial for building reliable integrations with monday.com.

## Why Rate Limiting Exists

Rate limiting serves two primary purposes:

### 1. Protecting the API Infrastructure

Without rate limits, a single client could overwhelm the API with requests, degrading performance for all users. Rate limits ensure fair distribution of resources and prevent accidental (or intentional) abuse.

Think of it like a highway: without speed limits and traffic control, congestion would make the road unusable for everyone. Rate limits are the "traffic control" of APIs.

### 2. Encouraging Efficient API Usage

Rate limits incentivize developers to write efficient queries. Instead of making 100 requests for individual items, you're encouraged to batch them into a single request. This benefits both you (fewer network round-trips) and the API (fewer requests to process).

## Monday.com's Rate Limiting Strategy

Unlike many APIs that use simple request-per-second limits, monday.com uses a **complexity budget** system. This is more sophisticated and fair.

### Complexity Budget Model

Each monday.com account gets a **complexity budget** that regenerates over time:
- Budget regenerates at a fixed rate (e.g., 100,000 points per minute)
- Each query consumes points based on its complexity
- Simple queries cost few points; complex queries cost many
- When budget depleted, requests are rate limited until budget regenerates

**Why complexity-based?** It's fairer. A simple query that fetches one field shouldn't cost the same as a complex query joining multiple resources. Complexity budgets reward efficient queries.

### Example:

```ruby
# Low complexity (~10 points)
client.board.query(
  ids: [12345],
  select: ['id', 'name']
)

# High complexity (~500 points)
client.board.query(
  ids: [12345],
  select: [
    'id', 'name', 'description',
    { 'groups' => ['id', 'title', { 'items' => ['id', 'name', 'column_values'] }] }
  ]
)
```

The second query traverses multiple relationships and returns much more data, so it costs more.

## Complexity Calculation and Query Cost

Understanding query cost helps you stay within your complexity budget.

### Factors That Increase Complexity:

1. **Nested relationships**: Each level of nesting adds cost
   ```ruby
   # Low cost
   select: ['id', 'name']

   # Medium cost
   select: ['id', 'name', { 'items' => ['id', 'name'] }]

   # High cost
   select: ['id', { 'groups' => ['id', { 'items' => ['id', { 'column_values' => ['id', 'text'] }] }] }]
   ```

2. **Number of fields**: More fields = higher cost
   ```ruby
   # Lower cost
   select: ['id', 'name']

   # Higher cost
   select: ['id', 'name', 'description', 'state', 'board_kind', 'permissions', 'created_at', 'updated_at']
   ```

3. **Number of results**: Fetching 100 items costs more than fetching 10
   ```ruby
   # Lower cost
   client.item.query(ids: [123], limit: 10)

   # Higher cost
   client.item.query(ids: [123], limit: 100)
   ```

4. **Computed fields**: Fields that require calculation are more expensive

### Estimating Query Cost

monday.com's GraphQL API includes complexity information in responses. You can log this to understand your queries:

```ruby
response = client.board.query(ids: [board_id])
complexity = response.dig('account_id', 'complexity')  # If available in response
logger.info("Query complexity: #{complexity}")
```

**Rule of thumb**: Start simple and add fields incrementally. Monitor which queries cause rate limiting and optimize those.

## Rate Limiting Strategies: Proactive vs Reactive

There are two fundamental approaches to handling rate limits:

### Reactive Strategy (Handle Errors)

Wait until you hit the rate limit, then back off:

```ruby
def fetch_with_reactive_limiting
  begin
    client.board.query(ids: [board_id])
  rescue Monday::ComplexityError => e
    # Rate limited - wait and retry
    sleep(60)
    retry
  end
end
```

**Pros:**
- Simple to implement
- No complexity tracking needed
- Maximizes throughput when under limit

**Cons:**
- Requests fail and must be retried
- Unpredictable latency (sudden delays when limit hit)
- Can create thundering herd if multiple processes retry simultaneously

### Proactive Strategy (Track and Throttle)

Track your complexity usage and throttle before hitting the limit:

```ruby
class ComplexityTracker
  def initialize(budget_per_minute: 100_000)
    @budget = budget_per_minute
    @used = 0
    @window_start = Time.now
  end

  def track_request(estimated_cost)
    reset_if_new_window

    if @used + estimated_cost > @budget
      wait_time = 60 - (Time.now - @window_start)
      sleep(wait_time) if wait_time > 0
      reset_window
    end

    @used += estimated_cost
  end

  private

  def reset_if_new_window
    if Time.now - @window_start >= 60
      reset_window
    end
  end

  def reset_window
    @used = 0
    @window_start = Time.now
  end
end
```

**Pros:**
- Predictable latency (no sudden rate limit errors)
- Better for user experience (no failed requests)
- More efficient (no wasted retry attempts)

**Cons:**
- Complex to implement
- Requires tracking state
- May be overly conservative (wasting budget)

### Hybrid Strategy (Best of Both)

Use proactive throttling with reactive fallback:

```ruby
def fetch_with_hybrid_limiting
  tracker.track_request(estimated_complexity: 100)

  begin
    client.board.query(ids: [board_id])
  rescue Monday::ComplexityError => e
    # Reactive fallback if estimation was wrong
    logger.warn("Hit rate limit despite throttling")
    sleep(60)
    retry
  end
end
```

This combines the predictability of proactive throttling with the safety net of reactive handling.

## Exponential Backoff: Why It Works

When you do hit a rate limit, exponential backoff is the gold standard retry strategy.

### Linear Backoff (Don't Use)

```ruby
# Bad: Linear backoff
retry_count.times do |i|
  sleep((i + 1) * 5)  # 5s, 10s, 15s, 20s
  retry
end
```

**Problem**: If many clients are rate-limited simultaneously (common during outages), they all retry at similar intervals, creating synchronized "waves" of requests that re-trigger the rate limit.

### Exponential Backoff (Use This)

```ruby
# Good: Exponential backoff
retry_count.times do |i|
  sleep(2 ** i)  # 1s, 2s, 4s, 8s, 16s, 32s
  retry
end
```

**Why it works**:
1. **Backs off quickly**: Gives the API (and your budget) time to recover
2. **Disperses retries**: Different processes retry at different times
3. **Self-limiting**: Long delays naturally limit retry attempts

### Adding Jitter (Even Better)

```ruby
# Best: Exponential backoff with jitter
retry_count.times do |i|
  base_delay = 2 ** i
  jitter = rand(0..base_delay * 0.1)  # Add 0-10% randomness
  sleep(base_delay + jitter)
  retry
end
```

**Jitter** adds randomness to prevent synchronized retries. If 100 clients are rate-limited at the same moment, jitter ensures they don't all retry at exactly the same time.

## Queuing Requests: Benefits and Trade-offs

For high-volume integrations, queuing requests can smooth out traffic and prevent rate limiting.

### Basic Queue Pattern

```ruby
class MondayRequestQueue
  def initialize(requests_per_minute: 60)
    @queue = Queue.new
    @rate = requests_per_minute
    start_worker
  end

  def enqueue(request)
    @queue.push(request)
  end

  private

  def start_worker
    Thread.new do
      loop do
        request = @queue.pop
        execute_request(request)
        sleep(60.0 / @rate)  # Throttle to stay under limit
      end
    end
  end

  def execute_request(request)
    request.call
  rescue Monday::Error => e
    handle_error(e, request)
  end
end
```

### Benefits:

1. **Smooth traffic**: Requests sent at steady rate, not bursts
2. **Automatic throttling**: Queue ensures you never exceed rate limit
3. **Resilience**: Failed requests can be re-queued
4. **Prioritization**: Implement priority queues for urgent requests

### Trade-offs:

1. **Added latency**: Requests wait in queue before execution
2. **Complexity**: Requires queue management, monitoring, error handling
3. **Memory usage**: Large queues consume memory
4. **Lost requests**: Queue contents lost if process crashes (use persistent queue like Sidekiq/Redis)

### When to Use:

- **High volume**: Processing hundreds/thousands of requests per hour
- **Background jobs**: Non-interactive operations where latency is acceptable
- **Batch operations**: Syncing large datasets

### When Not to Use:

- **Interactive requests**: Users waiting for immediate responses
- **Low volume**: Simple applications with occasional API calls
- **Real-time needs**: Time-sensitive operations where queuing delay is unacceptable

## Caching Responses: When It Helps

Caching API responses can dramatically reduce your rate limit consumption.

### What to Cache

**Good candidates:**
- Reference data (board schemas, column definitions)
- Slow-changing data (board names, user lists)
- Frequently accessed data (current user info)

**Poor candidates:**
- Real-time data (item status updates)
- User-specific data (for multi-user apps)
- Large datasets (memory constraints)

### Cache Implementation

```ruby
def get_board_schema(board_id)
  cache_key = "monday_board_schema_#{board_id}"

  Rails.cache.fetch(cache_key, expires_in: 1.hour) do
    client.board.query(
      ids: [board_id],
      select: ['id', 'name', { 'columns' => ['id', 'title', 'type'] }]
    )
  end
end
```

### TTL Considerations

Choosing the right Time-To-Live (TTL) is an art:

**Short TTL (minutes):**
- Use for: Moderately dynamic data (item counts, recent updates)
- Pro: More accurate data
- Con: More API calls, less rate limit savings

**Medium TTL (hours):**
- Use for: Slowly changing data (board configuration, user lists)
- Pro: Balance between freshness and efficiency
- Con: Data can be stale for parts of the day

**Long TTL (days):**
- Use for: Static reference data (workspace structure, column types)
- Pro: Maximum rate limit savings
- Con: Stale data if structure changes

**Indefinite (manual invalidation):**
- Use for: Truly static data
- Pro: Zero API calls for cached data
- Con: Must invalidate on changes (complex)

### Cache Invalidation

The hard part of caching is knowing when to invalidate:

```ruby
def update_board(board_id, attributes)
  result = client.board.update(board_id: board_id, **attributes)

  # Invalidate cache after update
  Rails.cache.delete("monday_board_schema_#{board_id}")
  Rails.cache.delete("monday_board_items_#{board_id}")

  result
end
```

**Cache invalidation strategies:**

1. **Time-based (TTL)**: Simplest, works for most use cases
2. **Event-based**: Invalidate when data changes (requires tracking)
3. **Versioned keys**: Include version in cache key, bump on change
4. **Background refresh**: Refresh cache before expiry (always fresh, no cache misses)

## Optimizing Query Complexity

The best way to avoid rate limiting is to reduce query complexity.

### Technique 1: Request Only Needed Fields

```ruby
# Bad: Fetching everything (high complexity)
client.board.query(
  ids: [board_id],
  select: ['id', 'name', 'description', 'state', 'board_kind',
           'permissions', { 'groups' => ['id', 'title', { 'items' => ['id', 'name'] }] }]
)

# Good: Fetching only what's needed (low complexity)
client.board.query(
  ids: [board_id],
  select: ['id', 'name', { 'groups' => ['id'] }]
)
```

**Every field has a cost**. Only request fields you actually use.

### Technique 2: Pagination Over Large Queries

```ruby
# Bad: Fetch all items at once (very high complexity)
client.item.query_by_board(
  board_id: board_id,
  limit: 1000
)

# Good: Paginate in smaller chunks (distributed complexity)
page = 1
loop do
  items = client.item.query_by_board(
    board_id: board_id,
    limit: 25,
    page: page
  )

  break if items.empty?
  process_items(items)
  page += 1
  sleep(0.5)  # Small delay between pages
end
```

Pagination spreads complexity over time, staying within your budget.

### Technique 3: Batch Related Requests

```ruby
# Bad: Multiple queries (high total complexity)
boards.each do |board_id|
  client.board.query(ids: [board_id])
end

# Good: Single batched query (lower total complexity)
client.board.query(ids: board_ids)
```

monday.com's API supports fetching multiple resources in one query. Use it.

### Technique 4: Denormalize When Possible

If you frequently need the same data, consider storing it locally:

```ruby
# Instead of querying monday.com every time
def get_item_status(item_id)
  client.item.query(ids: [item_id], select: ['status'])
end

# Store status locally and sync periodically
class Item < ApplicationRecord
  def self.sync_statuses
    items = client.item.query(ids: Item.pluck(:monday_id), select: ['id', 'status'])
    items.each do |item_data|
      Item.find_by(monday_id: item_data['id']).update(status: item_data['status'])
    end
  end
end
```

**Trade-off**: Data staleness vs. API efficiency. Choose based on your freshness requirements.

## Monitoring Rate Limit Usage

You can't optimize what you don't measure.

### What to Monitor

1. **Rate limit errors**: How often are you hitting the limit?
2. **Complexity per query**: Which queries are most expensive?
3. **Total complexity**: How much of your budget are you using?
4. **Retry frequency**: How many retries are needed?

### Monitoring Implementation

```ruby
class MondayApiMonitor
  def self.track_request(query, complexity, duration)
    StatsD.increment('monday.api.requests')
    StatsD.gauge('monday.api.complexity', complexity)
    StatsD.timing('monday.api.duration', duration)
  end

  def self.track_rate_limit_error
    StatsD.increment('monday.api.rate_limit_errors')
    alert_if_threshold_exceeded
  end

  private

  def self.alert_if_threshold_exceeded
    error_rate = get_error_rate
    if error_rate > 0.05  # Alert if >5% of requests rate limited
      notify_team("Monday API rate limit errors elevated: #{error_rate}")
    end
  end
end
```

### Setting Alerts

Configure alerts for:
- **High error rate**: >5% of requests rate limited
- **Approaching budget**: Using >80% of complexity budget
- **Sudden spikes**: Complexity usage increases >50% hour-over-hour

Early warning allows you to optimize before users are impacted.

## Distributed Rate Limiting Challenges

In distributed systems (multiple servers/processes), rate limiting becomes complex.

### The Problem

Each process doesn't know what the others are doing:

```ruby
# Process 1
client.board.query(...)  # Uses 1000 complexity points

# Process 2 (simultaneously)
client.board.query(...)  # Also uses 1000 complexity points

# Combined: 2000 points consumed, but neither process knows
```

If each process thinks it has the full budget, they'll collectively exceed the limit.

### Solution 1: Centralized Rate Limiter

Use Redis to track shared complexity budget:

```ruby
class DistributedRateLimiter
  def initialize(redis, budget_per_minute: 100_000)
    @redis = redis
    @budget = budget_per_minute
  end

  def acquire(cost)
    key = "monday_complexity:#{Time.now.to_i / 60}"  # Per-minute key

    @redis.watch(key)
    used = @redis.get(key).to_i

    if used + cost > @budget
      @redis.unwatch
      return false  # Budget exceeded
    end

    @redis.multi do
      @redis.incrby(key, cost)
      @redis.expire(key, 120)  # Expire after 2 minutes
    end

    true
  end
end

# Usage
unless rate_limiter.acquire(estimated_cost)
  sleep(60)  # Wait for next window
  retry
end

client.board.query(...)
```

### Solution 2: Partition Budget

Divide complexity budget among processes:

```ruby
# If you have 4 worker processes
process_budget = TOTAL_BUDGET / 4

# Each process tracks its own portion
tracker = ComplexityTracker.new(budget_per_minute: process_budget)
```

**Trade-off**: May underutilize budget if some processes are idle while others are busy.

### Solution 3: Queue-Based (Recommended)

Use a centralized queue (Sidekiq, etc.) with a single worker:

```ruby
# All processes enqueue requests
MondayRequestJob.perform_async(board_id: board_id)

# Single worker processes queue at controlled rate
class MondayRequestJob
  include Sidekiq::Job
  sidekiq_options throttle: { threshold: 60, period: 1.minute }

  def perform(board_id:)
    client.board.query(ids: [board_id])
  end
end
```

This naturally serializes requests and prevents distributed rate limiting issues.

## Key Takeaways

1. **Understand complexity budgets**: monday.com uses complexity, not simple request counts
2. **Be proactive**: Track usage and throttle before hitting limits
3. **Use exponential backoff**: When rate limited, back off exponentially with jitter
4. **Cache strategically**: Cache slow-changing data with appropriate TTLs
5. **Optimize queries**: Request only needed fields, paginate large datasets
6. **Monitor actively**: Track complexity usage, error rates, and set alerts
7. **Queue for scale**: Use queues for high-volume, distributed systems
8. **Test your limits**: Understand your actual complexity budget through monitoring

Rate limiting isn't a obstacle—it's a design constraint that encourages efficient, scalable API usage. Work with it, not against it.
