# Design Decisions

This document explores the key design decisions behind the monday_ruby gem, explaining the rationale, trade-offs, and principles that guide its implementation.

## Table of Contents

- [Design Philosophy](#design-philosophy)
- [Client-Resource Pattern Choice](#client-resource-pattern-choice)
- [Configuration Design](#configuration-design)
- [Error Exception Hierarchy](#error-exception-hierarchy)
- [GraphQL Abstraction Level](#graphql-abstraction-level)
- [Response Object Design](#response-object-design)
- [The base64 Dependency](#the-base64-dependency)
- [Future Design Considerations](#future-design-considerations)

## Design Philosophy

The monday_ruby gem is built on several core principles that inform all design decisions:

### 1. Ruby-Idiomatic Interface

The gem should feel natural to Ruby developers, even if they've never used GraphQL. This means:
- Using snake_case method names (`board.query` not `board.Query`)
- Accepting Ruby data structures (hashes, arrays, symbols)
- Following Ruby conventions for error handling (exceptions, not error codes)
- Providing sensible defaults that work for common cases

### 2. Explicit Over Implicit

While the gem hides GraphQL complexity, it remains explicit about what it's doing:
- Method names clearly indicate the operation (`create`, `query`, `update`, `delete`)
- Users explicitly specify what data they want via the `select` parameter
- No hidden network calls or lazy loading
- Query building is transparent (the query string could be logged/inspected)

### 3. Flexibility Without Complexity

The gem provides simple defaults for common cases while allowing customization:
- Default field selections for quick usage
- Override options for specific needs
- Extensible architecture for adding resources
- No forced opinions about how to structure application code

### 4. Fail Fast and Clearly

When things go wrong, the gem should make it obvious:
- Specific exception types for different error categories
- Response objects attached to exceptions for debugging
- No silent failures or generic error messages
- API errors are surfaced, not swallowed

These principles create a gem that's approachable for beginners but powerful for advanced users.

## Client-Resource Pattern Choice

The decision to use a client-resource pattern rather than alternative approaches deserves deeper exploration.

### The Decision

Resources are instantiated through the client and hold a reference back to it:

```ruby
client = Monday::Client.new(token: "...")
client.board.query(...)  # client.board is a Board instance
```

Rather than:
- Static methods: `Monday::Board.query(client, ...)`
- Standalone instances: `board = Monday::Board.new(token: "...")`
- Global configuration: `Monday.configure(...); Monday::Board.query(...)`

### Why This Design?

**1. Configuration Scoping**

By tying resources to a client instance, configuration becomes scoped:

```ruby
client_a = Monday::Client.new(token: "token_a")
client_b = Monday::Client.new(token: "token_b")

client_a.board.query(...)  # Uses token_a
client_b.board.query(...)  # Uses token_b
```

This is critical for applications that interact with multiple monday.com accounts or need different configurations (like different timeouts) for different request types.

**2. Dependency Injection**

Resources receive their dependencies (the client) through their constructor. This makes testing easier:

```ruby
# In tests
mock_client = double("Client")
board = Monday::Resources::Board.new(mock_client)
```

Resources don't need global state or singleton instances to function.

**3. Discoverability**

The client acts as a namespace for all available resources. You can discover what's available by exploring the client:

```ruby
client.methods.grep(/^[a-z]/)  # Shows all resource accessors
```

This is harder with static methods spread across multiple classes.

**4. Shared State**

All resources on a client share the same configuration, connection, and error handling. This ensures consistency:

```ruby
client = Monday::Client.new(
  token: "...",
  open_timeout: 5,
  read_timeout: 30
)

# All resources use the same timeouts
client.board.query(...)
client.item.create(...)
client.group.delete(...)
```

### Trade-offs

**Advantages:**
- Configuration scoping (multiple clients possible)
- Clear dependency relationships
- Consistent behavior across resources
- Easy to test with mocks

**Disadvantages:**
- More verbose than static methods: `client.board.query(...)` vs `Board.query(...)`
- Resources can't be used independently (always need a client)
- Extra initialization step (creating the client)

For a library wrapping an authenticated API, these trade-offs favor the client-resource pattern. The scoping and dependency injection benefits outweigh the verbosity.

## Configuration Design

The gem supports both global and instance-level configuration, which is unusual. Most libraries choose one approach.

### The Dual System

**Global Configuration:**
```ruby
Monday.configure do |config|
  config.token = "..."
  config.version = "2023-07"
end

client = Monday::Client.new  # Uses global config
```

**Instance Configuration:**
```ruby
client = Monday::Client.new(
  token: "...",
  version: "2023-07"
)  # Creates its own config
```

### Why Both?

This design serves different use cases:

**Global configuration** is ideal for:
- Simple applications with one monday.com account
- Setting defaults for all clients
- Quick prototyping and scripts
- Rails applications (config in an initializer)

**Instance configuration** is ideal for:
- Multi-tenant applications
- Testing (different configs for different test scenarios)
- Applications integrating with multiple monday.com accounts
- Overriding specific settings for specific requests

### Implementation Details

The implementation is elegantly simple:

```ruby
def configure(config_args)
  return Monday.config if config_args.empty?
  Configuration.new(**config_args)
end
```

If no arguments are provided, use the global singleton. Otherwise, create a new `Configuration` instance. This means:

- No global client instance (would prevent multiple configurations)
- Global config is lazy-loaded (created on first access)
- Instance configs are independent (don't affect global or each other)

### Alternative Approaches

**Only Global Configuration:**
Many Ruby libraries (like Octokit, Faraday) use only global configuration. This is simpler but makes multi-tenant scenarios difficult:

```ruby
# Hard to manage multiple accounts
Monday.configure(token: "account_a_token")
result_a = Monday::Board.query(...)

Monday.configure(token: "account_b_token")  # Overwrites!
result_b = Monday::Board.query(...)
```

**Only Instance Configuration:**
Some libraries require explicit configuration for every client. This is flexible but verbose for single-account applications:

```ruby
# Repetitive in simple cases
client1 = Monday::Client.new(token: "...", version: "2023-07", host: "...")
client2 = Monday::Client.new(token: "...", version: "2023-07", host: "...")
```

**Inheritance Pattern:**
Some libraries allow instance configs to inherit from global and override selectively:

```ruby
Monday.configure do |config|
  config.version = "2023-07"
  config.host = "https://api.monday.com/v2"
end

client = Monday::Client.new(token: "...")  # Inherits version and host, sets token
```

The current design doesn't support inheritance. Instance configs are completely independent from global config. This is simpler to understand (no merge logic) but less flexible.

### Trade-offs

The dual system is more complex than a single approach, but it serves real use cases. The simplicity of the implementation (just return global or create instance) keeps maintenance burden low.

Future versions could add inheritance if user demand exists, but the current design satisfies the common cases.

## Error Exception Hierarchy

The gem defines a hierarchy of exception classes that mirror monday.com's error types.

### The Hierarchy

```
Monday::Error (base)
├── Monday::InternalServerError (500)
├── Monday::AuthorizationError (401, 403)
├── Monday::RateLimitError (429)
├── Monday::ResourceNotFoundError (404)
├── Monday::InvalidRequestError (400)
└── Monday::ComplexityError (GraphQL complexity)
```

### Design Rationale

**1. Catchall with Specificity**

Users can rescue all API errors:
```ruby
rescue Monday::Error => e
  # Handle any monday.com error
end
```

Or specific types:
```ruby
rescue Monday::RateLimitError => e
  sleep 60
  retry
rescue Monday::AuthorizationError => e
  refresh_token
  retry
rescue Monday::Error => e
  log_error(e)
end
```

**2. HTTP Semantics**

The exception hierarchy follows HTTP status code semantics. This makes the gem's behavior predictable to developers familiar with REST APIs, even though monday.com uses GraphQL.

**3. Rich Error Objects**

All exceptions include:
- `message`: Human-readable error description
- `response`: The full Response object for debugging
- `code`: HTTP status code or custom error code

This allows detailed error handling:
```ruby
rescue Monday::Error => e
  puts "Error: #{e.message}"
  puts "Status: #{e.code}"
  puts "Body: #{e.response.body.inspect}"
  puts "Error data: #{e.error_data.inspect}"
end
```

### The Mapping Problem

monday.com returns errors in inconsistent formats:
- HTTP status codes (401, 404, 429, 500)
- GraphQL error codes (`ComplexityException`, `USER_UNAUTHORIZED`)
- Different key names (`code` vs `error_code`)
- Errors in arrays vs. top-level objects

The gem handles this with two mapping methods:

**`Util.status_code_exceptions_mapping`** - Maps HTTP codes to exceptions:
```ruby
{
  "500" => InternalServerError,
  "429" => RateLimitError,
  "404" => ResourceNotFoundError,
  # ...
}
```

**`Util.response_error_exceptions_mapping`** - Maps API error codes to exceptions:
```ruby
{
  "ComplexityException" => [ComplexityError, 429],
  "USER_UNAUTHORIZED" => [AuthorizationError, 403],
  "InvalidBoardIdException" => [InvalidRequestError, 400],
  # ...
}
```

The client tries both approaches:
1. Check HTTP status code → raise default exception if not 2xx
2. Check response body error codes → raise specific exception

This handles both HTTP-level errors (network issues, auth failures) and GraphQL-level errors (invalid queries, business logic failures).

### Why Not One Generic Exception?

A single `Monday::Error` would be simpler:

```ruby
# Hypothetical simpler design
raise Monday::Error.new(message: error_message, code: error_code)
```

But this loses semantic information. Users would have to check error codes or messages to determine the error type:

```ruby
rescue Monday::Error => e
  if e.code == 429
    # Rate limit
  elsif e.code == 401
    # Auth error
  end
end
```

Specific exception types make error handling clearer and more robust (error messages can change, but exception types are part of the API contract).

### Trade-offs

**Advantages:**
- Semantic error handling (rescue specific types)
- Follows HTTP conventions
- Rich error information
- Extensible (new exception types can be added)

**Disadvantages:**
- More classes to maintain
- Mapping tables need updates when monday.com adds error codes
- Users must learn the exception hierarchy

The benefits of semantic error handling outweigh the maintenance cost, especially as the gem matures and error types stabilize.

## GraphQL Abstraction Level

A key design question is: How much GraphQL should the gem expose?

### The Chosen Abstraction

The gem provides a **high-level abstraction** that hides GraphQL entirely:

```ruby
client.board.query(
  args: {ids: [123]},
  select: ["id", "name", {"items" => ["id"]}]
)
```

Users don't write GraphQL queries. They call Ruby methods with Ruby data structures.

### Alternative Abstraction Levels

**Low-Level (Expose GraphQL):**
```ruby
client.execute(<<~GRAPHQL)
  query {
    boards(ids: [123]) {
      id
      name
      items { id }
    }
  }
GRAPHQL
```

**Medium-Level (Query builders):**
```ruby
client.query do |q|
  q.boards(ids: [123]) do |b|
    b.field :id
    b.field :name
    b.field :items do |i|
      i.field :id
    end
  end
end
```

**High-Level (Hide GraphQL):**
```ruby
client.board.query(args: {ids: [123]}, select: ["id", "name", {"items" => ["id"]}])
```

### Why High-Level?

**1. Accessibility**

Most Ruby developers haven't used GraphQL. By hiding it, the gem is accessible to a broader audience. Users can be productive without learning GraphQL syntax, schema introspection, or query optimization.

**2. Consistency**

All methods follow the same pattern: `args` for parameters, `select` for fields. This consistency makes the API predictable. Once you understand `board.query`, you understand `item.query`.

**3. Simplicity**

No query builder DSL to learn. No GraphQL client library to understand. Just method calls with hashes and arrays.

**4. Monday.com Specifics**

The abstraction can encode monday.com-specific knowledge:

```ruby
# Default field selections that make sense for monday.com
def query(args: {}, select: DEFAULT_SELECT)
  # DEFAULT_SELECT = ["id", "name", "description"]
end
```

Users get sensible defaults without knowing what fields exist.

### Trade-offs

**Advantages:**
- No GraphQL knowledge required
- Consistent API across resources
- Defaults encode monday.com best practices
- Simple to use for common cases

**Disadvantages:**
- Can't use all GraphQL features (aliases, fragments, directives)
- Abstraction can leak (some monday.com concepts don't map cleanly)
- Less flexible than raw GraphQL
- Users must learn the gem's API instead of standard GraphQL

### When the Abstraction Leaks

The high-level abstraction sometimes reveals its GraphQL underpinnings:

**Field selection syntax** mirrors GraphQL structure:
```ruby
select: ["id", {"items" => ["id", "name"]}]
# Generates: id items { id name }
```

**Arguments** use GraphQL types:
```ruby
args: {operator: :and}  # Symbol becomes GraphQL enum
args: {rules: [...]}    # Array becomes GraphQL list
```

These aren't pure Ruby APIs - they're GraphQL concepts exposed through Ruby syntax.

### Future Direction

The abstraction could evolve in two directions:

**More abstraction**: Hide even the field selection:
```ruby
client.board.find(123)  # Returns a board object with default fields
client.board.find(123, include: [:items])  # Include related items
```

**Less abstraction**: Expose an escape hatch for raw GraphQL:
```ruby
client.execute(graphql_query_string)
```

The current design balances these extremes. It's high-level enough for ease of use but low-level enough to expose GraphQL's power (explicit field selection, complex queries).

## Response Object Design

The gem wraps `Net::HTTP::Response` in a custom `Monday::Response` class rather than returning the raw response.

### The Design

```ruby
class Response
  attr_reader :status, :body, :headers

  def initialize(response)
    @status = response.code.to_i
    @body = parse_body  # Parses JSON
    @headers = parse_headers
  end

  def success?
    (200..299).cover?(status) && !errors?
  end
end
```

### Why Wrap?

**1. Consistent Interface**

`Net::HTTP::Response` has quirks:
- `response.code` is a string ("200"), not an integer
- `response.body` is raw JSON, not parsed
- Headers are accessed with `response.each_header`

The wrapper provides a cleaner, more predictable interface:
- `response.status` is always an integer
- `response.body` is always a parsed hash
- `response.headers` is a simple hash

**2. monday.com Specifics**

The `success?` method encodes monday.com-specific knowledge:

```ruby
def success?
  (200..299).cover?(status) && !errors?
end
```

monday.com returns HTTP 200 for GraphQL errors, so HTTP status alone doesn't indicate success. The wrapper checks both HTTP status and response body.

**3. Future Evolution**

The wrapper provides a stable API even if the underlying HTTP library changes. If the gem switches from `Net::HTTP` to `httparty` or `faraday`, the Response interface can remain the same.

**4. Exception Context**

All exceptions include the Response object:

```ruby
exception.response.body
exception.response.status
exception.response.headers
```

This wouldn't work cleanly with raw `Net::HTTP::Response` because it doesn't guarantee a parsed body or integer status.

### Alternative: Return Raw Response

The gem could return `Net::HTTP::Response` directly:

```ruby
http_response = client.board.query(...)
body = JSON.parse(http_response.body)
```

**Advantages:**
- Users can access all `Net::HTTP::Response` methods
- No abstraction layer
- Familiar to Ruby developers

**Disadvantages:**
- Users must parse JSON themselves
- No monday.com-specific success detection
- Less consistent (status is string vs integer confusion)
- Tied to Net::HTTP (harder to change HTTP library)

### Trade-offs

The wrapper adds a thin abstraction layer, but it significantly improves usability:

```ruby
# With wrapper
response = client.board.query(...)
if response.success?
  boards = response.body["data"]["boards"]
end

# Without wrapper (hypothetical)
response = client.board.query(...)
if response.code.to_i.between?(200, 299)
  parsed = JSON.parse(response.body)
  unless parsed["errors"] || parsed["error_code"]
    boards = parsed["data"]["boards"]
  end
end
```

The wrapper encapsulates complexity that users would otherwise repeat in every integration.

## The base64 Dependency

The gem explicitly depends on the `base64` gem, even though the code never directly requires or uses Base64 encoding. This decision requires explanation.

### The Issue

Starting with Ruby 3.4, `base64` was removed from Ruby's default gems. It must be explicitly added as a dependency to Gemfile.

The monday_ruby gem uses `Net::HTTP` for HTTP requests. `Net::HTTP` internally requires `base64` for HTTP Basic Authentication, even if the gem doesn't use Basic Auth.

Without the explicit dependency, the gem would fail on Ruby 3.4+ with:
```
LoadError: cannot load such file -- base64
```

### The Decision

Rather than letting users discover this error in production, the gem explicitly declares the dependency:

```ruby
# In gemspec
spec.add_dependency "base64", "~> 0.2.0"
```

### Why Not Remove Net::HTTP?

The gem could switch to an HTTP library that doesn't require `base64`:
- `httparty`
- `faraday`
- `rest-client`

However:
- `Net::HTTP` is in Ruby's standard library (no external dependencies until Ruby 3.4)
- It's simple and well-understood
- The gem's HTTP needs are basic (POST requests with JSON)
- Switching would add dependencies for Ruby < 3.4 users

Adding `base64` as a dependency is simpler than changing HTTP libraries.

### Future Considerations

As Ruby 3.4+ adoption grows, this decision may be revisited. Options include:
- Keep the `base64` dependency (current approach)
- Switch to a different HTTP library
- Conditionally require `base64` only on Ruby 3.4+

For now, explicit dependency on `base64` is the simplest solution that works across all Ruby versions.

## Future Design Considerations

Design decisions aren't permanent. As the gem evolves, several areas merit reconsideration.

### 1. Query Caching

Currently, every request hits the monday.com API. Future versions could cache responses:

```ruby
client = Monday::Client.new(token: "...", cache: Redis.new)
client.board.query(args: {ids: [123]})  # Hits API
client.board.query(args: {ids: [123]})  # Returns cached response
```

**Considerations:**
- Cache invalidation is hard (when does cached data become stale?)
- monday.com data changes frequently (boards, items updated constantly)
- Would complicate the simple request-response model
- Adds dependency on cache backend

Caching might be better left to application code using the gem.

### 2. Async/Batch Requests

The gem could support batching multiple queries:

```ruby
client.batch do |batch|
  batch.board.query(args: {ids: [123]})
  batch.item.query(args: {ids: [456]})
  batch.group.query(args: {ids: [789]})
end  # Executes all queries in one HTTP request
```

GraphQL supports this natively. The gem could expose it.

**Considerations:**
- Batch requests are more complex (partial failures, ordering)
- monday.com's API may have batch size limits
- The simple one-method-one-request model would break
- Testing becomes harder (mocking batch responses)

This would be a significant design change requiring careful thought.

### 3. Pagination Helpers

The gem exposes monday.com's cursor-based pagination but doesn't provide helpers:

```ruby
# Current approach
response = client.board.items_page(board_id: 123, limit: 100)
items = response.body.dig("data", "boards", 0, "items_page", "items")
cursor = response.body.dig("data", "boards", 0, "items_page", "cursor")

response = client.board.items_page(board_id: 123, cursor: cursor)
# Repeat...
```

A pagination helper could simplify this:

```ruby
# Hypothetical helper
client.board.items_page(board_id: 123).each_page do |items, cursor|
  process(items)
  break if cursor.nil?
end

# Or automatic pagination
all_items = client.board.all_items(board_id: 123)  # Fetches all pages
```

**Considerations:**
- Auto-pagination could make many API calls without users realizing
- Rate limiting becomes more complex
- Adds stateful behavior (tracking cursors)
- Different monday.com resources paginate differently

Pagination helpers would need careful design to avoid surprising behavior.

### 4. Response Object Enhancement

The Response object could provide convenience methods:

```ruby
response = client.board.query(args: {ids: [123]})

# Current approach
boards = response.body.dig("data", "boards")

# Enhanced approach
boards = response.data.boards  # Method chaining
boards = response.boards        # Even simpler
```

**Considerations:**
- Requires understanding monday.com's response structure
- Different queries return different structures
- Could hide response complexity (good or bad?)
- Adds magic (method_missing or dynamic method definition)

This would make common cases simpler but could confuse debugging.

### 5. Validation

The gem could validate arguments before making requests:

```ruby
client.board.query(args: {ids: "not an array"})
# Currently: monday.com API returns error
# Could: Gem raises ArgumentError immediately
```

**Considerations:**
- Requires duplicating monday.com's validation logic
- monday.com's API evolves (validation rules change)
- Validation errors vs. API errors (different exception types?)
- Adds maintenance burden

Early validation helps users but couples the gem to monday.com's current API.

## Conclusion

The monday_ruby gem's design emerged from specific goals and constraints:

- **Client-resource pattern**: Balances organization, discoverability, and flexibility
- **Dual configuration**: Serves both simple and complex use cases
- **Exception hierarchy**: Enables semantic error handling
- **High-level abstraction**: Prioritizes accessibility over GraphQL power
- **Response wrapper**: Provides consistency and monday.com-specific logic
- **Explicit dependencies**: Ensures compatibility across Ruby versions

These decisions involve trade-offs. The design optimizes for:
1. Ease of use for Ruby developers new to monday.com
2. Explicit behavior over hidden magic
3. Flexibility for advanced users
4. Maintainability as monday.com's API evolves

Future evolution will balance these goals against emerging use cases and community feedback. Good design isn't about perfect decisions - it's about thoughtful trade-offs that serve the majority of users while remaining open to change.
