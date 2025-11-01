# Pagination in monday.com

This document explains pagination concepts and how they apply to the monday.com API and the monday_ruby gem.

## What is Pagination?

Pagination is the practice of dividing large datasets into smaller, manageable chunks called "pages." Instead of retrieving thousands of records in a single API request, pagination allows you to fetch data incrementally.

### Why Pagination is Necessary

1. **Performance**: Loading thousands of items at once would be slow for both the server and client
2. **Memory**: Large datasets can exhaust available memory, especially on mobile devices
3. **Timeout prevention**: Long-running requests risk timing out before completion
4. **User experience**: Users can see results immediately rather than waiting for everything to load
5. **Network efficiency**: Smaller responses are faster to transmit and more resilient to connection issues
6. **Rate limiting**: Spreading requests across time helps stay within API rate limits

### The Alternative

Without pagination, fetching all items from a board with 10,000 items would:
- Take 10+ seconds to complete
- Use several megabytes of bandwidth
- Risk timeout on slower connections
- Potentially hit API complexity limits
- Load data users may never view

## Cursor-Based vs Offset-Based Pagination

There are two primary pagination strategies, each with distinct trade-offs.

### Offset-Based Pagination

Uses numeric offsets to specify starting positions:

```
GET /items?offset=0&limit=25   # First page
GET /items?offset=25&limit=25  # Second page
GET /items?offset=50&limit=25  # Third page
```

**Advantages**:
- Simple to understand and implement
- Direct access to any page (e.g., "jump to page 5")
- Easy to calculate total pages

**Disadvantages**:
- Inconsistent results if data changes between requests (items added/deleted)
- Inefficient for large offsets (database must skip many rows)
- Difficult to handle concurrent modifications
- "Page drift" when items are added/removed during pagination

**Example of page drift**:
```
Initial state: [A, B, C, D, E, F, G, H]

Request 1 (offset=0, limit=3): Returns [A, B, C]
New item X inserted at position 0: [X, A, B, C, D, E, F, G, H]
Request 2 (offset=3, limit=3): Returns [C, D, E]
Result: Item C appears twice, B is skipped
```

### Cursor-Based Pagination

Uses opaque tokens (cursors) to mark positions in a dataset:

```
GET /items?cursor=initial&limit=25
# Response includes next_cursor: "eyJpZCI6MTIzfQ=="

GET /items?cursor=eyJpZCI6MTIzfQ==&limit=25
# Response includes next_cursor: "eyJpZCI6MTQ4fQ=="
```

**Advantages**:
- Consistent results even when data changes
- Efficient at any depth in the dataset
- Handles concurrent modifications gracefully
- No duplicate or skipped items

**Disadvantages**:
- Cannot jump to arbitrary pages
- Cannot calculate total page count easily
- Cursors can become invalid
- More complex implementation

## Why monday.com Uses Cursor-Based Pagination

monday.com adopted cursor-based pagination for several architectural reasons:

### Real-Time Collaboration

monday.com is a collaborative platform where multiple users modify boards simultaneously:
- Items are created and deleted constantly
- Items move between groups
- Board structure changes frequently

Cursor-based pagination ensures that when you're iterating through items, you get a consistent view even as the board changes.

### Scalability

Large boards can have tens of thousands of items. Cursor-based pagination:
- Maintains consistent performance regardless of position in the dataset
- Uses database indexes efficiently
- Avoids expensive offset calculations

### API Design Philosophy

monday.com's GraphQL API emphasizes:
- **Reliability**: Cursors prevent duplicate or missed items
- **Efficiency**: Each request is optimized for the current state
- **Consistency**: The same cursor always points to the same logical position

## How Cursor Pagination Works

### Opaque Cursors

Cursors in monday.com are opaque strings - their internal structure is implementation-dependent and subject to change. A cursor might encode:
- Item ID
- Timestamp
- Sort order
- Filter criteria

**Important**: Treat cursors as opaque tokens. Never:
- Parse or decode cursors
- Construct cursors manually
- Make assumptions about cursor format
- Store cursors long-term

### Pagination Flow

1. **Initial request**: Don't provide a cursor
   ```ruby
   response = client.item.items_page(
     args: { limit: 25, query_params: { boards: [123] } }
   )
   ```

2. **Extract cursor**: Get the cursor from the response
   ```ruby
   cursor = response.dig("data", "items_page", "cursor")
   ```

3. **Subsequent requests**: Pass the cursor to get the next page
   ```ruby
   next_page = client.item.items_page(
     args: { limit: 25, cursor: cursor, query_params: { boards: [123] } }
   )
   ```

4. **Detect end**: When there's no more data, the cursor may be nil or empty

### Cursor Characteristics

- **Stateful**: Encodes position in a specific query result set
- **Query-specific**: A cursor from one query won't work with a different query
- **Time-sensitive**: Cursors expire after a certain period
- **Opaque**: Internal format is not guaranteed or documented
- **Forward-only**: Can only move forward through results

## Cursor Expiration

monday.com cursors expire after **60 minutes** of inactivity.

### Why Cursors Expire

1. **Resource management**: Servers don't maintain pagination state indefinitely
2. **Data consistency**: Prevents using stale cursors on significantly changed data
3. **Security**: Limits the window for cursor-based attacks or abuse
4. **Cache invalidation**: Allows backend caches to be cleared periodically

### Handling Expiration

When a cursor expires:
- The API returns an error indicating the cursor is invalid
- You must restart pagination from the beginning
- Previously fetched data remains valid

### Best Practices

- **Process promptly**: Don't hold cursors for extended periods
- **Handle errors**: Detect expired cursor errors and restart
- **Avoid storing**: Don't persist cursors in databases or long-term storage
- **Complete iterations**: Finish paginating through results in a single session when possible

### Expiration Example

```ruby
# Start pagination at 10:00 AM
cursor = get_first_page_cursor()

# Wait 65 minutes...

# Use cursor at 11:05 AM - will fail!
begin
  next_page = get_page(cursor)
rescue Monday::InvalidCursorError
  # Cursor expired, restart pagination
  cursor = get_first_page_cursor()
  next_page = get_page(cursor)
end
```

## Pagination Performance Considerations

### Page Size Trade-offs

Choosing the right page size (limit parameter) involves balancing competing factors:

**Small pages (e.g., 10-25 items)**:
- Lower latency per request
- Less memory usage
- More requests needed to fetch all data
- Higher total time for complete dataset
- More API calls (impacts rate limits)

**Large pages (e.g., 100-500 items)**:
- Higher latency per request
- More memory usage
- Fewer requests needed
- Lower total time for complete dataset
- Fewer API calls

**Optimal page size depends on**:
- Network speed and reliability
- Available memory
- UI/UX requirements (how much to show at once)
- Rate limit constraints
- Total dataset size

### monday.com Limits

monday.com enforces limits on page size:
- Maximum items per page varies by endpoint
- Typically capped at 100-500 items
- Larger limits consume more API complexity budget

### Network Efficiency

Cursor-based pagination is network-efficient:
- Only requested data is transmitted
- Subsequent requests reuse connection pooling
- Cursors are small (typically under 100 bytes)
- Partial failures can be retried from last successful cursor

### Caching Considerations

Cursor-based pagination affects caching strategies:
- Individual pages can be cached using cursor as key
- Cache expiration should align with cursor expiration (60 minutes)
- First page (no cursor) is often most heavily cached
- Personalized or filtered queries are harder to cache

## items_page vs Deprecated items Field

monday.com's GraphQL API has evolved its pagination approach.

### Legacy: items Field

The original `items` field on boards returned all items without pagination:

```graphql
query {
  boards(ids: [123]) {
    items {
      id
      name
    }
  }
}
```

**Problems**:
- No pagination support
- Returns all items at once
- Performance degrades with large boards
- Timeout risk on boards with many items
- High API complexity cost

### Modern: items_page Query

The `items_page` query provides cursor-based pagination:

```graphql
query {
  items_page(limit: 25, query_params: {boards: [123]}) {
    cursor
    items {
      id
      name
    }
  }
}
```

**Advantages**:
- Efficient pagination with cursors
- Consistent performance regardless of board size
- Lower complexity per request
- Better resource utilization
- Query parameters for filtering

### Migration Path

monday.com deprecated the `items` field to encourage pagination:
- New applications should use `items_page`
- Existing applications should migrate to avoid deprecation
- The `items` field may be removed in future API versions

The monday_ruby gem provides methods for both:
- `client.board.items` - legacy (deprecated)
- `client.item.items_page` - modern (recommended)

## Query Parameters and Filtering with Pagination

The `items_page` query supports filtering through query parameters, which interact with pagination in important ways.

### Query Parameters

Common filters include:
- `boards`: Limit to specific boards
- `state`: Filter by item state (active, archived, deleted)
- `order_by`: Sort order for results

```ruby
client.item.items_page(
  args: {
    limit: 25,
    query_params: {
      boards: [123, 456],
      state: "active",
      order_by: [{ column_id: "date", direction: "desc" }]
    }
  }
)
```

### Cursor-Filter Coupling

Cursors are tied to their query parameters:
- A cursor from a filtered query only works with the same filter
- Changing `query_params` invalidates the cursor
- The cursor encodes both position and query context

**Example of what NOT to do**:
```ruby
# Request 1: Filter by board 123
response1 = items_page(query_params: { boards: [123] })
cursor = response1["cursor"]

# Request 2: Try to use cursor with different filter - ERROR!
response2 = items_page(cursor: cursor, query_params: { boards: [456] })
# This will fail - cursor is specific to board 123
```

### Filtering Best Practices

1. **Keep filters consistent**: Use identical `query_params` throughout pagination
2. **Filter early**: Apply filters in the initial request, not on fetched results
3. **Understand costs**: Complex filters may increase API complexity
4. **Combine operations**: Fetch and filter in a single request rather than multiple

### Pagination with Sorting

When using `order_by`, cursors maintain the sort order:
- Results remain sorted across all pages
- Cursor position is relative to the sorted sequence
- Changing sort order invalidates the cursor

## Trade-offs: Page Size vs API Calls

Determining optimal pagination strategy requires analyzing multiple dimensions.

### Scenario 1: Display 25 Items to User

If you only need to show 25 items:
- Set `limit: 25`
- Make 1 API call
- Minimal complexity
- Fastest time-to-display

### Scenario 2: Process All 1,000 Items

If you need to process every item on a board:

**Option A: Small pages (25 items)**
- 40 API calls required
- 40× authentication overhead
- 40× network round-trips
- Lower memory footprint
- Can start processing sooner
- More resilient to failures (restart from last cursor)

**Option B: Large pages (100 items)**
- 10 API calls required
- 10× authentication overhead
- 10× network round-trips
- Higher memory footprint
- Longer wait before processing starts
- More data lost on failure

### Scenario 3: Rate-Limited Environment

If you're close to rate limits:
- Larger pages reduce total API calls
- But larger pages have higher complexity per call
- Must balance: fewer calls vs complexity budget
- May need to add delays between requests

### Scenario 4: Real-Time Updates

If displaying data as it loads:
- Smaller pages provide faster initial display
- Users see results immediately
- Can implement infinite scroll or "load more"
- Better perceived performance

### Calculation Example

Board with 1,000 items, rate limit of 100 requests/minute:

**25-item pages**:
- Requests needed: 40
- Time at max rate: 24 seconds (within limit)
- Memory per page: ~25 KB
- Total transfer: ~1 MB

**100-item pages**:
- Requests needed: 10
- Time at max rate: 6 seconds
- Memory per page: ~100 KB
- Total transfer: ~1 MB

Same total data transferred, but different time and memory profiles.

## Conclusion

Pagination is a fundamental aspect of working with the monday.com API. Understanding cursor-based pagination - its advantages over offset pagination, how cursors work, their expiration behavior, and the trade-offs in page sizing - is essential for building efficient, reliable applications.

Key takeaways:
- monday.com uses cursor-based pagination for consistency and performance
- Cursors are opaque, stateful, and expire after 60 minutes
- Use `items_page` instead of the deprecated `items` field
- Page size involves trade-offs between latency, memory, and API calls
- Query parameters must remain consistent throughout pagination
- Proper pagination design significantly impacts application performance and user experience

The monday_ruby gem abstracts the mechanics of cursor handling while preserving GraphQL's pagination semantics, but understanding these underlying concepts enables you to make informed decisions about pagination strategy in your applications.
