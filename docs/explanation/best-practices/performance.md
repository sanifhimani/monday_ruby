# Performance Best Practices

Performance in API integrations isn't just about speed—it's about efficiency, reliability, and cost. This guide explores the key considerations and trade-offs when building performant applications with the monday_ruby gem.

## Performance Considerations in API Integrations

API integration performance differs fundamentally from traditional application performance.

### What Makes API Performance Different

**Database queries**: Microseconds, local, predictable
**API calls**: Milliseconds to seconds, remote, variable

The primary performance bottleneck in API integrations is **network latency**. No amount of code optimization can eliminate the fundamental cost of:
- Network round-trip time (~10-100ms)
- API processing time (~50-500ms)
- Data serialization/deserialization (~1-10ms)

This means **reducing the number of API calls** is far more impactful than optimizing how you make those calls.

### The Performance Triangle

You can optimize for three dimensions, but rarely all at once:

```
    Latency
      /\
     /  \
    /    \
   /______\
  Cost    Throughput
```

**Latency**: Time to complete a single request (user-facing)
**Throughput**: Total requests processed per second (system capacity)
**Cost**: API quota, complexity budget, infrastructure

Optimizing one often degrades another:
- Lower latency → Higher cost (parallel requests use more quota)
- Higher throughput → Higher latency (queueing delays)
- Lower cost → Lower throughput (fewer requests, more caching)

Choose your priority based on your use case.

## Query Optimization: Select Only Needed Fields

The simplest and most effective optimization is requesting only what you need.

### The Cost of Extra Fields

Every field in a GraphQL query has a cost:

```ruby
# Expensive: 500+ complexity points
client.board.query(
  ids: [board_id],
  select: [
    'id', 'name', 'description', 'state', 'board_kind',
    'board_folder_id', 'permissions', 'type', 'owner',
    { 'groups' => [
      'id', 'title', 'color', 'position',
      { 'items' => [
        'id', 'name', 'state', 'created_at', 'updated_at',
        { 'column_values' => ['id', 'text', 'value', 'type'] }
      ]}
    ]}
  ]
)

# Efficient: 50 complexity points
client.board.query(
  ids: [board_id],
  select: ['id', 'name']
)
```

**Impact**: 10x complexity reduction → 10x more queries within rate limit

### Field Selection Strategy

**Start minimal, add incrementally:**

```ruby
# Step 1: Identify minimum needed
select: ['id', 'name']  # Just need to display board name

# Step 2: Add only when required
select: ['id', 'name', 'state']  # Need to filter by state

# Step 3: Add nested data carefully
select: ['id', 'name', { 'groups' => ['id', 'title'] }]  # Need group names
```

**Don't guess**: Use logging to identify unnecessary fields:

```ruby
def fetch_board_data(board_id)
  response = client.board.query(ids: [board_id], select: fields)

  # Log which fields are actually used
  used_fields = track_field_access(response)
  logger.debug("Fields requested: #{fields}")
  logger.debug("Fields actually used: #{used_fields}")

  response
end
```

If you request 20 fields but only use 5, you're wasting complexity budget.

### Template Queries for Common Use Cases

Define reusable field sets:

```ruby
module MondayQueries
  BOARD_SUMMARY = ['id', 'name', 'state'].freeze

  BOARD_DETAILED = [
    'id', 'name', 'description', 'state',
    { 'groups' => ['id', 'title'] }
  ].freeze

  BOARD_WITH_ITEMS = [
    'id', 'name',
    { 'groups' => [
      'id', 'title',
      { 'items' => ['id', 'name'] }
    ]}
  ].freeze
end

# Use templates
client.board.query(
  ids: [board_id],
  select: MondayQueries::BOARD_SUMMARY
)
```

This ensures consistency and makes optimization easier (change template, all queries improve).

## Pagination Strategies for Large Datasets

Fetching large datasets requires pagination. The strategy you choose dramatically impacts performance.

### Strategy 1: Offset Pagination (Simple)

Request data in fixed-size pages:

```ruby
def fetch_all_items_offset(board_id)
  all_items = []
  page = 1
  limit = 50

  loop do
    items = client.item.query_by_board(
      board_id: board_id,
      limit: limit,
      page: page
    ).dig('data', 'items')

    break if items.empty?

    all_items.concat(items)
    page += 1
  end

  all_items
end
```

**Pros:**
- Simple to implement
- Can jump to any page
- Familiar pattern

**Cons:**
- Slower for large datasets (database skips over offset records)
- Inconsistent results if data changes during pagination
- Higher complexity for later pages

**When to use**: Small to medium datasets (<1000 records), random page access needed

### Strategy 2: Cursor Pagination (Efficient)

Use a cursor to track position:

```ruby
def fetch_all_items_cursor(board_id)
  all_items = []
  cursor = nil

  loop do
    response = client.item.query_by_board(
      board_id: board_id,
      limit: 50,
      cursor: cursor
    )

    items = response.dig('data', 'items')
    break if items.empty?

    all_items.concat(items)
    cursor = response.dig('data', 'cursor')  # Next page cursor
    break unless cursor
  end

  all_items
end
```

**Pros:**
- Efficient for large datasets (database uses index)
- Consistent results during pagination
- Lower complexity

**Cons:**
- Can't jump to arbitrary pages
- More complex to implement
- Not supported by all monday.com endpoints

**When to use**: Large datasets (>1000 records), sequential access patterns

### Strategy 3: Parallel Pagination (Fast)

Fetch multiple pages simultaneously:

```ruby
def fetch_all_items_parallel(board_id, total_pages: 10)
  # Fetch first 10 pages in parallel
  responses = (1..total_pages).map do |page|
    Thread.new do
      client.item.query_by_board(
        board_id: board_id,
        limit: 50,
        page: page
      )
    end
  end.map(&:value)

  responses.flat_map { |r| r.dig('data', 'items') || [] }
end
```

**Pros:**
- Much faster (parallel network requests)
- Good for bounded datasets

**Cons:**
- Higher rate limit consumption (burst of requests)
- More complex error handling
- Requires knowing total pages upfront

**When to use**: Known dataset size, latency-critical operations, ample rate limit budget

### Strategy 4: Adaptive Pagination (Smart)

Adjust page size based on performance:

```ruby
def fetch_all_items_adaptive(board_id)
  all_items = []
  page = 1
  limit = 25  # Start conservative

  loop do
    start_time = Time.now
    items = client.item.query_by_board(
      board_id: board_id,
      limit: limit,
      page: page
    ).dig('data', 'items')

    duration = Time.now - start_time

    break if items.empty?
    all_items.concat(items)

    # Adapt page size based on response time
    if duration < 0.5
      limit = [limit * 2, 100].min  # Increase if fast
    elsif duration > 2.0
      limit = [limit / 2, 10].max   # Decrease if slow
    end

    page += 1
  end

  all_items
end
```

**Pros:**
- Self-optimizing
- Handles variable performance
- Balances speed and reliability

**Cons:**
- Complex implementation
- Unpredictable behavior
- May oscillate under variable load

**When to use**: Highly variable dataset sizes or API performance

### Choosing a Pagination Strategy

| Dataset Size | Access Pattern | Rate Limit | Strategy |
|--------------|----------------|------------|----------|
| <500 items | Full scan | Ample | Offset, large pages |
| <500 items | Random access | Limited | Offset, small pages |
| 500-5000 items | Full scan | Ample | Parallel offset |
| 500-5000 items | Full scan | Limited | Cursor |
| >5000 items | Full scan | Any | Cursor |
| >5000 items | Recent items | Any | Cursor, stop early |

## Batching Operations Efficiently

Batching reduces API calls by combining multiple operations.

### Request Batching

Fetch multiple resources in one request:

```ruby
# Inefficient: N+1 queries
board_ids.each do |board_id|
  client.board.query(ids: [board_id])  # 10 boards = 10 API calls
end

# Efficient: Single batched query
client.board.query(ids: board_ids)  # 10 boards = 1 API call
```

**Impact**: 10x reduction in API calls, 10x reduction in latency (eliminate 9 round-trips)

### Batch Size Considerations

Bigger batches aren't always better:

```ruby
# Too small: Many API calls
item_ids.each_slice(5) do |batch|
  client.item.query(ids: batch)  # 100 items = 20 calls
end

# Too large: High complexity, timeouts
client.item.query(ids: item_ids)  # 1000 items = 1 call, but may timeout

# Optimal: Balance efficiency and reliability
item_ids.each_slice(50) do |batch|
  client.item.query(ids: batch)  # 100 items = 2 calls
end
```

**Optimal batch size**: 25-100 items (depends on complexity of fields requested)

### Mutation Batching

Some mutations can be batched:

```ruby
# If API supports batch mutations
updates = [
  { item_id: 1, column_values: { status: 'Done' } },
  { item_id: 2, column_values: { status: 'Done' } },
  { item_id: 3, column_values: { status: 'Done' } }
]

# Check if monday.com API supports batch mutations for your use case
client.item.batch_update(updates)  # Single API call
```

**Note**: Not all mutations support batching. Check API documentation.

### Temporal Batching (Debouncing)

Collect requests over time, then batch:

```ruby
class RequestBatcher
  def initialize(window: 1.0)
    @window = window
    @pending = []
    @timer = nil
  end

  def add(item_id)
    @pending << item_id
    schedule_flush
  end

  private

  def schedule_flush
    return if @timer

    @timer = Thread.new do
      sleep(@window)
      flush
    end
  end

  def flush
    return if @pending.empty?

    batch = @pending.dup
    @pending.clear
    @timer = nil

    client.item.query(ids: batch)
  end
end

# Usage: Collect IDs over 1 second, then fetch in batch
batcher = RequestBatcher.new(window: 1.0)
batcher.add(item_id_1)
batcher.add(item_id_2)
batcher.add(item_id_3)
# After 1 second: single API call with all 3 IDs
```

**Use case**: High-frequency updates (webhooks, real-time sync)

## Caching Strategies and Invalidation

Caching eliminates API calls entirely—the ultimate optimization.

### What to Cache

**High-value cache candidates:**
- Reference data (rarely changes, frequently accessed)
- Computed results (expensive to generate)
- Rate limit state (prevent redundant checks)

**Poor cache candidates:**
- Real-time data (stale data causes issues)
- User-specific data (cache hit rate too low)
- Large datasets (memory constraints)

### Cache Layers

Implement multiple cache layers:

```ruby
# Layer 1: In-memory (fastest, smallest)
@board_cache ||= {}

# Layer 2: Redis (fast, shared across processes)
Rails.cache  # Configured to use Redis

# Layer 3: Database (slower, persistent)
CachedBoard.find_by(monday_id: board_id)

# Layer 4: API (slowest, source of truth)
client.board.query(ids: [board_id])
```

Check layers in order, falling through to API only if all caches miss:

```ruby
def get_board_with_multilayer_cache(board_id)
  # Layer 1: In-memory
  return @board_cache[board_id] if @board_cache[board_id]

  # Layer 2: Redis
  cached = Rails.cache.read("board_#{board_id}")
  if cached
    @board_cache[board_id] = cached
    return cached
  end

  # Layer 3: Database
  db_cached = CachedBoard.find_by(monday_id: board_id)
  if db_cached && db_cached.fresh?
    Rails.cache.write("board_#{board_id}", db_cached.data, expires_in: 1.hour)
    @board_cache[board_id] = db_cached.data
    return db_cached.data
  end

  # Layer 4: API
  fresh_data = client.board.query(ids: [board_id])

  # Populate all caches
  @board_cache[board_id] = fresh_data
  Rails.cache.write("board_#{board_id}", fresh_data, expires_in: 1.hour)
  CachedBoard.upsert(monday_id: board_id, data: fresh_data)

  fresh_data
end
```

### Cache Invalidation Strategies

#### 1. Time-Based (TTL)

Simplest: Cache expires after fixed duration:

```ruby
Rails.cache.fetch("board_#{board_id}", expires_in: 1.hour) do
  client.board.query(ids: [board_id])
end
```

**Pros:** Simple, no invalidation logic needed
**Cons:** Data can be stale for full TTL period

**Choosing TTL:**
- Static data: 24 hours - 1 week
- Slow-changing data: 1-6 hours
- Moderate data: 5-60 minutes
- Fast-changing data: 30 seconds - 5 minutes

#### 2. Write-Through Invalidation

Invalidate cache when data changes:

```ruby
def update_board(board_id, attributes)
  result = client.board.update(board_id: board_id, **attributes)

  # Invalidate cache immediately
  Rails.cache.delete("board_#{board_id}")
  @board_cache.delete(board_id)

  result
end
```

**Pros:** Data always fresh after updates
**Cons:** Doesn't handle external changes (updates from monday.com UI)

#### 3. Webhook-Based Invalidation

Listen for monday.com webhooks to invalidate:

```ruby
# Webhook endpoint
post '/webhooks/monday' do
  event = JSON.parse(request.body.read)

  case event['type']
  when 'update_board'
    Rails.cache.delete("board_#{event['board_id']}")
  when 'update_item'
    # Invalidate board cache (item count may have changed)
    Rails.cache.delete("board_items_#{event['board_id']}")
  end
end
```

**Pros:** Invalidates based on actual changes
**Cons:** Requires webhook setup, network reliability

#### 4. Background Refresh

Refresh cache before expiry (always fresh, no cache misses):

```ruby
class BoardCacheRefresher
  def perform
    Board.find_each do |board|
      fresh_data = client.board.query(ids: [board.monday_id])
      Rails.cache.write("board_#{board.monday_id}", fresh_data, expires_in: 1.hour)
    end
  end
end

# Schedule every 30 minutes (before 1-hour TTL expires)
```

**Pros:** No cache misses, always fresh data
**Cons:** Continuous API usage, wasted refreshes for unused data

### Cache Key Design

Good cache keys prevent collisions and enable targeted invalidation:

```ruby
# Bad: Global cache (hard to invalidate)
Rails.cache.fetch('boards') { ... }

# Good: Specific cache with identifiers
Rails.cache.fetch("board:#{board_id}:v1") { ... }

# Better: Include query parameters
Rails.cache.fetch("board:#{board_id}:fields:#{fields.hash}:v1") { ... }

# Best: Versioned with dependencies
Rails.cache.fetch("board:#{board_id}:user:#{user_id}:v2") { ... }
```

Include versions (`v1`, `v2`) to invalidate all caches when schema changes.

## Connection Pooling and Timeouts

Managing HTTP connections affects both performance and reliability.

### Connection Pooling

Reuse HTTP connections instead of creating new ones:

```ruby
# Without pooling: New connection per request (slow)
Net::HTTP.start(uri.host, uri.port) do |http|
  http.request(request)
end

# With pooling: Reuse existing connections (fast)
@connection_pool ||= ConnectionPool.new(size: 10) do
  Net::HTTP.start(uri.host, uri.port, use_ssl: true)
end

@connection_pool.with do |http|
  http.request(request)
end
```

**Benefits:**
- Eliminate connection overhead (~50-100ms per connection)
- Reduce server load
- Better throughput

**Pool size considerations:**
- Too small: Threads wait for available connections
- Too large: Excessive memory usage, server connection limits
- Rule of thumb: 5-10 per worker process

### Timeout Configuration

Timeouts prevent indefinite waiting:

```ruby
http = Net::HTTP.new(uri.host, uri.port)
http.open_timeout = 5   # Time to establish connection
http.read_timeout = 30  # Time to read response
http.write_timeout = 10 # Time to send request

begin
  http.request(request)
rescue Net::OpenTimeout
  # Connection couldn't be established
  retry_with_backoff
rescue Net::ReadTimeout
  # Request sent but response took too long
  log_slow_request
  raise
end
```

**Timeout values:**
- **Open timeout**: 3-5 seconds (connection should be fast)
- **Read timeout**: 30-60 seconds (complex queries take time)
- **Write timeout**: 10-15 seconds (uploads can be slow)

**Trade-offs:**
- Short timeouts: Fail fast, better user experience, may abort valid slow requests
- Long timeouts: More reliable, but users wait longer for errors

## Async Processing Patterns

Asynchronous processing decouples API calls from user requests.

### Background Jobs

Move API calls to background:

```ruby
# Synchronous (user waits)
def sync_board
  client.board.query(ids: [board_id])  # User waits for API call
  render json: { status: 'synced' }
end

# Asynchronous (user doesn't wait)
def sync_board
  SyncBoardJob.perform_async(board_id)  # Queue job
  render json: { status: 'queued' }     # Immediate response
end

# Background job
class SyncBoardJob
  include Sidekiq::Worker

  def perform(board_id)
    client.board.query(ids: [board_id])  # Runs in background
  end
end
```

**Benefits:**
- Immediate user response
- Retry on failure
- Rate limit management (queue throttling)

**Drawbacks:**
- User doesn't see immediate results
- Requires job infrastructure (Sidekiq, Redis)

### Async I/O

Use async HTTP libraries for concurrent requests:

```ruby
require 'async'
require 'async/http/internet'

Async do
  internet = Async::HTTP::Internet.new

  # Fetch multiple boards concurrently
  tasks = board_ids.map do |board_id|
    Async do
      response = internet.get("https://api.monday.com/v2/boards/#{board_id}")
      JSON.parse(response.read)
    end
  end

  # Wait for all to complete
  results = tasks.map(&:wait)
end
```

**Benefits:**
- Concurrent I/O without threads
- Lower memory overhead
- Efficient for I/O-bound operations

**Drawbacks:**
- Different programming model
- Library compatibility issues

### Webhooks Instead of Polling

Replace polling with webhooks:

```ruby
# Polling (inefficient)
loop do
  response = client.board.query(ids: [board_id])
  check_for_changes(response)
  sleep(60)  # API call every minute
end

# Webhooks (efficient)
post '/webhooks/monday' do
  event = JSON.parse(request.body.read)
  handle_change(event)  # Only called when actual changes occur
end
```

**Benefits:**
- Zero polling overhead
- Instant notifications
- Dramatic reduction in API calls

**Drawbacks:**
- Requires public endpoint
- Network reliability dependency
- Initial setup complexity

## Memory Management with Large Responses

Large API responses can cause memory issues.

### Streaming Responses

Process data incrementally instead of loading all at once:

```ruby
# Bad: Load entire response into memory
response = client.board.query(ids: board_ids)  # Could be 100MB
all_items = response.dig('data', 'boards').flat_map { |b| b['items'] }

# Good: Process in chunks
board_ids.each_slice(10) do |batch|
  response = client.board.query(ids: batch)  # Smaller responses
  items = response.dig('data', 'boards').flat_map { |b| b['items'] }

  process_items(items)  # Process and release memory
  GC.start  # Force garbage collection if needed
end
```

### Lazy Evaluation

Use enumerators for on-demand loading:

```ruby
def item_enumerator(board_id)
  Enumerator.new do |yielder|
    page = 1

    loop do
      items = client.item.query_by_board(
        board_id: board_id,
        page: page,
        limit: 50
      ).dig('data', 'items')

      break if items.empty?

      items.each { |item| yielder << item }
      page += 1
    end
  end
end

# Usage: Only loads pages as needed
item_enumerator(board_id).each do |item|
  process_item(item)  # Items processed one at a time
end
```

### JSON Streaming Parsers

Parse JSON incrementally:

```ruby
require 'json/stream'

# Instead of JSON.parse(huge_response)
parser = JSON::Stream::Parser.new do
  start_object { |key| }
  end_object { |key| process_object(@current_object) }
  key { |k| @current_key = k }
  value { |v| @current_object[@current_key] = v }
end

response.body.each_chunk do |chunk|
  parser << chunk  # Parse incrementally
end
```

**Use when**: Responses >10MB, memory-constrained environments

## Monitoring and Profiling API Usage

You can't improve what you don't measure.

### Instrumentation

Add instrumentation to API calls:

```ruby
class Monday::Client
  def make_request(query)
    start_time = Time.now
    complexity_estimate = estimate_complexity(query)

    begin
      response = super(query)
      duration = Time.now - start_time

      log_metrics(
        duration: duration,
        complexity: complexity_estimate,
        success: true
      )

      response
    rescue Monday::Error => e
      log_metrics(
        duration: Time.now - start_time,
        complexity: complexity_estimate,
        success: false,
        error_class: e.class.name
      )
      raise
    end
  end

  private

  def log_metrics(metrics)
    logger.info("Monday API call: #{metrics.to_json}")

    # Send to monitoring system
    StatsD.timing('monday.api.duration', metrics[:duration])
    StatsD.gauge('monday.api.complexity', metrics[:complexity])
    StatsD.increment("monday.api.#{metrics[:success] ? 'success' : 'error'}")
  end
end
```

### Key Metrics to Track

1. **Latency percentiles**: p50, p95, p99 response times
2. **Error rate**: Percentage of failed requests
3. **Complexity usage**: Total complexity consumed per time window
4. **Rate limit hits**: How often hitting rate limits
5. **Cache hit rate**: Percentage of requests served from cache
6. **Throughput**: Requests per second

### Profiling Bottlenecks

Use Ruby profiling tools:

```ruby
require 'benchmark'

result = Benchmark.measure do
  client.board.query(ids: board_ids)
end

puts "API call took #{result.real} seconds"

# Or use more detailed profiling
require 'ruby-prof'

RubyProf.start
sync_all_boards
result = RubyProf.stop

printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)
```

### Alerting

Set up alerts for performance degradation:

```ruby
class PerformanceMonitor
  def check_api_performance
    avg_duration = get_average_duration(last: 5.minutes)

    if avg_duration > 2.0
      alert("Monday API latency elevated: #{avg_duration}s average")
    end

    error_rate = get_error_rate(last: 5.minutes)

    if error_rate > 0.05
      alert("Monday API error rate elevated: #{error_rate * 100}%")
    end
  end
end
```

## Trade-offs: Latency vs Throughput vs Cost

Different optimization strategies prioritize different dimensions.

### Optimizing for Latency (User Experience)

**Goal**: Minimize time to complete individual requests

**Strategies:**
- Parallel requests (fetch multiple resources simultaneously)
- Aggressive caching (serve from cache even if slightly stale)
- Request only essential fields
- Use CDN for static assets

**Trade-offs:**
- Higher cost (more API calls, bigger caches)
- Lower throughput (parallel requests consume more resources)

**Example:**
```ruby
# Fetch board and items in parallel
board_thread = Thread.new { client.board.query(ids: [board_id]) }
items_thread = Thread.new { client.item.query_by_board(board_id: board_id) }

board = board_thread.value
items = items_thread.value
# Result: ~2x faster than sequential
```

### Optimizing for Throughput (System Capacity)

**Goal**: Process maximum requests per second

**Strategies:**
- Queue requests, process in batches
- Connection pooling
- Async I/O
- Distributed processing

**Trade-offs:**
- Higher latency (queuing delays)
- More complex infrastructure

**Example:**
```ruby
# Queue and batch process
class BoardSyncQueue
  def self.add(board_id)
    QUEUE << board_id
  end

  def self.process
    while QUEUE.any?
      batch = QUEUE.pop(100)  # Process 100 at a time
      client.board.query(ids: batch)
    end
  end
end
# Result: 100x fewer API calls, but individual requests slower
```

### Optimizing for Cost (Efficiency)

**Goal**: Minimize API quota usage and infrastructure costs

**Strategies:**
- Aggressive caching (long TTLs)
- Batch operations
- Request minimal fields
- Lazy loading (only fetch when needed)

**Trade-offs:**
- Stale data (long cache TTLs)
- Higher latency (no parallel requests)
- Lower throughput (sequential processing)

**Example:**
```ruby
# Cache with long TTL, minimal fields
Rails.cache.fetch("board_#{board_id}", expires_in: 24.hours) do
  client.board.query(
    ids: [board_id],
    select: ['id', 'name']  # Only essential fields
  )
end
# Result: Minimal API usage, but data up to 24 hours stale
```

### Balancing the Triangle

Most applications need a balance:

```ruby
class BalancedBoardFetcher
  def fetch(board_id, strategy: :balanced)
    case strategy
    when :fast
      fetch_parallel_with_short_cache(board_id)
    when :efficient
      fetch_sequential_with_long_cache(board_id)
    when :balanced
      fetch_sequential_with_medium_cache(board_id)
    end
  end

  private

  def fetch_parallel_with_short_cache(board_id)
    # Optimize for latency
    Rails.cache.fetch("board_#{board_id}", expires_in: 5.minutes) do
      # Parallel fetching, full fields
    end
  end

  def fetch_sequential_with_long_cache(board_id)
    # Optimize for cost
    Rails.cache.fetch("board_#{board_id}", expires_in: 24.hours) do
      # Sequential, minimal fields
    end
  end

  def fetch_sequential_with_medium_cache(board_id)
    # Balance
    Rails.cache.fetch("board_#{board_id}", expires_in: 1.hour) do
      # Sequential, necessary fields
    end
  end
end
```

## Key Takeaways

1. **Reduce API calls first**: Biggest performance gain comes from fewer requests
2. **Select only needed fields**: Every field has a complexity cost
3. **Paginate intelligently**: Choose strategy based on dataset size and access pattern
4. **Batch operations**: Combine multiple operations into single requests
5. **Cache strategically**: Multi-layer caching with appropriate TTLs
6. **Use connection pooling**: Reuse connections to eliminate overhead
7. **Go async for scale**: Background jobs and async I/O for high-volume operations
8. **Manage memory**: Stream large responses, use lazy evaluation
9. **Monitor everything**: Track latency, throughput, errors, and complexity usage
10. **Know your priorities**: Optimize for latency, throughput, or cost based on your needs

Performance optimization is an ongoing process. Start with the biggest bottlenecks (usually number of API calls), measure the impact, and iterate.
