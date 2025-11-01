# Architecture Overview

This document explains the architectural design of the monday_ruby gem, exploring how its components work together and why they're designed this way.

## Table of Contents

- [Overall Architecture](#overall-architecture)
- [The Client-Resource Pattern](#the-client-resource-pattern)
- [Dynamic Resource Initialization](#dynamic-resource-initialization)
- [GraphQL Query Building](#graphql-query-building)
- [Request-Response Flow](#request-response-flow)
- [Error Handling Architecture](#error-handling-architecture)
- [Alternative Approaches](#alternative-approaches)

## Overall Architecture

The monday_ruby gem is built around a **client-resource architecture** that wraps the monday.com GraphQL API in Ruby classes. Rather than exposing raw GraphQL queries or providing REST-style endpoints, the gem presents a resource-oriented interface that feels natural to Ruby developers.

The architecture consists of three main layers:

1. **Client Layer** - The entry point that handles authentication, configuration, and HTTP communication
2. **Resource Layer** - Domain-specific classes for each monday.com resource (Board, Item, Group, etc.)
3. **Utility Layer** - Shared components for GraphQL query construction, error handling, and HTTP requests

This layered approach creates clear separation of concerns: resources focus on domain logic and query construction, the client handles communication, and utilities provide shared functionality.

## The Client-Resource Pattern

### Why This Pattern?

The client-resource pattern emerged from several design goals:

**1. Encapsulation of GraphQL Complexity**

monday.com's API is built on GraphQL, which is powerful but verbose. While GraphQL gives developers fine-grained control over data fetching, it requires understanding schema structure, query syntax, and field relationships. The client-resource pattern shields users from this complexity.

Instead of writing:
```ruby
query = "query{boards(ids: [123]){id name description items{id name}}}"
# Now figure out how to execute this...
```

Users work with Ruby methods:
```ruby
client = Monday::Client.new(token: "...")
client.board.query(args: {ids: [123]}, select: ["id", "name", "description"])
```

**2. Natural Organization by Domain**

monday.com has distinct concepts: boards, items, groups, columns, updates, workspaces, etc. By creating a resource class for each concept, the gem mirrors monday.com's domain model. Users can discover functionality by exploring resources that match their mental model of monday.com.

**3. Shared Infrastructure**

All resources share common needs: authentication, error handling, HTTP communication, and query building. The client-resource pattern allows resources to inherit shared behavior from `Resources::Base` while delegating infrastructure concerns to the client.

### How It Works

The pattern involves two main components:

**The Client** (`/Users/sanifhimani/Development/monday_ruby/lib/monday/client.rb`)

The client is initialized with configuration and creates instances of all resource classes:

```ruby
def initialize(config_args = {})
  @config = configure(config_args)
  Resources.initialize(self)
end
```

The client provides:
- Configuration management (tokens, endpoints, timeouts)
- Request execution (`make_request`)
- Response handling and error raising
- HTTP header construction

**Resources** (`/Users/sanifhimani/Development/monday_ruby/lib/monday/resources/`)

Each resource class inherits from `Resources::Base` and receives a reference to the client:

```ruby
class Base
  attr_reader :client

  def initialize(client)
    @client = client
  end

  protected

  def make_request(query)
    client.make_request(query)
  end
end
```

Resources build GraphQL queries and delegate execution to the client. For example, `Board#query`:

```ruby
def query(args: {}, select: DEFAULT_SELECT)
  request_query = "query{boards#{Util.format_args(args)}{#{Util.format_select(select)}}}"
  make_request(request_query)
end
```

This separation means resources focus on "what" to query, while the client handles "how" to execute it.

## Dynamic Resource Initialization

One of the most interesting aspects of the architecture is how resources are automatically discovered and attached to the client.

### The Mechanism

The `Resources` module (`/Users/sanifhimani/Development/monday_ruby/lib/monday/resources.rb`) uses Ruby metaprogramming to dynamically initialize resources:

```ruby
def self.initialize(client)
  constants.each do |constant|
    resource_class = const_get(constant)
    resource_name = constant.to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
    client.instance_variable_set("@#{resource_name}", resource_class.new(client))
    define_resource_accessor(client, resource_name) unless client.class.method_defined?(resource_name)
  end
end
```

This code:
1. Iterates over all constants in the `Resources` module (which are the resource classes)
2. Converts class names to snake_case (`Board` → `board`, `BoardView` → `board_view`)
3. Creates an instance of each resource, passing the client
4. Sets it as an instance variable on the client
5. Defines an attr_reader for accessing the resource

### Why This Approach?

This dynamic initialization provides several benefits:

**1. Automatic Registration**

Adding a new resource is as simple as creating a file in `lib/monday/resources/`. The file is automatically loaded (via `Dir[File.join(__dir__, "resources", "*.rb")].sort.each { |file| require file }`), and the resource becomes available on the client. No manual registration needed.

**2. Consistent Interface**

All resources follow the same naming convention automatically. `Board` becomes `client.board`, `ActivityLog` becomes `client.activity_log`. Developers can predict the accessor name from the class name.

**3. Single Responsibility**

Resources don't need to know about initialization logic. They simply inherit from `Base` and implement their methods. The `Resources` module handles the metaprogramming.

**4. Extensibility**

Third-party code could extend the `Resources` module with additional classes, and they would automatically be initialized and available on the client.

### Trade-offs

This approach has some trade-offs:

- **Implicit Behavior**: The client's interface isn't explicitly defined in code. You must look at the resources directory to know what methods are available.
- **IDE Support**: Some IDEs struggle with dynamically defined methods, making autocomplete harder.
- **Debugging**: Metaprogramming can make stack traces more complex.

However, the benefits of automatic registration and consistency outweigh these concerns for a library like this, where resources map cleanly to domain concepts.

## GraphQL Query Building

The gem translates Ruby method calls into GraphQL queries through the `Util` class (`/Users/sanifhimani/Development/monday_ruby/lib/monday/util.rb`).

### The Challenge

GraphQL has specific syntax requirements:

```graphql
query {
  boards(ids: [123, 456], limit: 10) {
    id
    name
    items {
      id
      name
    }
  }
}
```

The gem needs to convert Ruby hashes and arrays into this format while handling:
- Arguments: `{ids: [123, 456]}` → `(ids: [123, 456])`
- Field selection: `["id", "name", {"items" => ["id"]}]` → `id name items { id }`
- Value formatting: strings need quotes, integers don't, symbols are literals
- Nested structures: arrays within hashes, hashes within arrays

### The Solution

The `Util` class provides two main methods:

**`Util.format_args`** - Converts Ruby hashes to GraphQL arguments:

```ruby
Util.format_args({board_name: "My Board", workspace_id: 123})
# => "(board_name: \"My Board\", workspace_id: 123)"
```

It handles:
- String escaping (wrapping strings in quotes)
- Integer preservation (no quotes)
- JSON encoding for complex hashes (double-encoded for monday.com's API)
- Array formatting
- Symbol pass-through (for GraphQL enum values)

**`Util.format_select`** - Converts Ruby arrays/hashes to field selection:

```ruby
Util.format_select(["id", "name", {"items" => ["id", "name"]}])
# => "id name items { id name }"
```

It recursively processes arrays and hashes to create nested field selections.

### Why String Building?

The gem builds queries as strings rather than using a GraphQL client library like `graphql-client`. This design choice has important implications:

**Advantages:**
- **Simplicity**: No external GraphQL dependencies, just string manipulation
- **Transparency**: Generated queries are easy to debug (just print the string)
- **Flexibility**: Can support any GraphQL feature monday.com adds without library updates
- **Performance**: No query parsing or AST construction overhead

**Disadvantages:**
- **No validation**: Malformed queries aren't caught until the API responds
- **String escaping**: Must manually handle special characters and injection risks
- **No type safety**: Can't verify field names or argument types at build time

For this gem, simplicity and transparency outweigh validation benefits. The monday.com API provides clear error messages when queries are malformed, and the gem's error handling surfaces these to users.

## Request-Response Flow

Understanding how requests flow through the system illuminates the architecture's design.

### The Complete Flow

1. **User calls a resource method**
   ```ruby
   client.board.query(args: {ids: [123]}, select: ["id", "name"])
   ```

2. **Resource builds a GraphQL query string**
   ```ruby
   # Inside Board#query
   request_query = "query{boards(ids: [123]){id name}}"
   ```

3. **Resource calls `make_request` (inherited from Base)**
   ```ruby
   make_request(request_query)
   # Delegates to client.make_request(request_query)
   ```

4. **Client executes the HTTP request**
   ```ruby
   # Inside Client#make_request
   response = Request.post(uri, body, request_headers, ...)
   ```

5. **Request.post wraps Net::HTTP**
   ```ruby
   # Inside Request.post
   http = Net::HTTP.new(uri.host, uri.port)
   request = Net::HTTP::Post.new(uri.request_uri, headers)
   request.body = {"query" => query}.to_json
   http.request(request)
   ```

6. **Response is wrapped in Monday::Response**
   ```ruby
   # Back in Client#make_request
   handle_response(Response.new(response))
   ```

7. **Client checks for errors**
   ```ruby
   # Inside Client#handle_response
   return response if response.success?
   raise_errors(response)
   ```

8. **Response returned to user**
   ```ruby
   response.body # => {"data" => {"boards" => [...]}}
   ```

### Why This Flow?

This multi-step flow might seem complex, but each layer has a purpose:

**Resources**: Know the domain and GraphQL schema structure
**Client**: Manages authentication and error handling
**Request**: Abstracts HTTP details
**Response**: Provides a consistent interface to raw HTTP responses

This separation allows each component to change independently. For example:
- Resources can be added without changing the client
- The HTTP library could be swapped without touching resources
- Error handling logic is centralized in one place

## Error Handling Architecture

monday.com's API returns errors in multiple ways, and the gem's error handling architecture deals with this complexity.

### The Problem

Errors can appear as:

1. **HTTP status codes**: 401, 403, 404, 429, 500
2. **Error codes in the response body**: `ComplexityException`, `InvalidBoardIdException`, etc.
3. **GraphQL errors array**: `{"errors": [{"message": "...", "extensions": {"code": "..."}}]}`

Additionally, monday.com returns HTTP 200 for some errors (like malformed GraphQL queries), with error details in the response body.

### The Solution

The gem uses a two-tier error detection system:

**Tier 1: HTTP Status Codes** (`Client#default_exception`)

```ruby
def default_exception(response)
  Util.status_code_exceptions_mapping(response.status).new(response: response)
end
```

Maps status codes to exception classes:
- 401/403 → `AuthorizationError`
- 404 → `ResourceNotFoundError`
- 429 → `RateLimitError`
- 500 → `InternalServerError`

**Tier 2: Response Body Error Codes** (`Client#response_exception`)

```ruby
def response_exception(response)
  error_code = response_error_code(response)
  exception_klass, code = Util.response_error_exceptions_mapping(error_code)
  exception_klass.new(message: error_code, response: response, code: code)
end
```

Extracts error codes from multiple possible locations:
- `response.body["error_code"]`
- `response.body.dig("errors", 0, "extensions", "code")`
- `response.body.dig("errors", 0, "extensions", "error_code")`

Then maps them to specific exceptions like `ComplexityError`, `InvalidBoardIdException`, etc.

### Success Detection

The `Response#success?` method combines both checks:

```ruby
def success?
  (200..299).cover?(status) && !errors?
end

def errors?
  (parse_body.keys & ERROR_OBJECT_KEYS).any?
end
```

A response is only successful if:
1. HTTP status is 2xx
2. Response body doesn't contain `errors`, `error_code`, or `error_message` keys

This handles monday.com's quirk of returning 200 for GraphQL errors.

### Exception Hierarchy

All exceptions inherit from `Monday::Error`, allowing users to rescue all monday.com errors with a single rescue clause:

```ruby
begin
  client.board.query(...)
rescue Monday::Error => e
  puts "API error: #{e.message}"
  puts "Response: #{e.response.body}"
end
```

Specific exceptions allow targeted error handling:

```ruby
rescue Monday::RateLimitError => e
  sleep(60)
  retry
rescue Monday::AuthorizationError => e
  refresh_token
  retry
```

### Why This Complexity?

The error handling is complex because it must handle:
- monday.com's evolving API (new error codes appear)
- Multiple error code formats (monday.com changed formats over time)
- HTTP vs. application-level errors
- User expectations (want specific exception types, but also a catch-all)

The architecture provides specificity when needed, but gracefully degrades to generic `Monday::Error` for unknown error codes.

## Alternative Approaches

To understand why monday_ruby is designed this way, it's useful to consider alternatives.

### Alternative 1: Direct GraphQL Client

The gem could expose a thin wrapper around a GraphQL client:

```ruby
client = Monday::Client.new(token: "...")
query = <<~GRAPHQL
  query {
    boards(ids: [123]) {
      id
      name
    }
  }
GRAPHQL

response = client.execute(query)
```

**Trade-offs:**
- ✅ Maximum flexibility - can use any GraphQL feature
- ✅ Familiar to GraphQL users
- ❌ Requires GraphQL knowledge
- ❌ Verbose for common operations
- ❌ No Ruby-idiomatic interface
- ❌ Error handling less structured

This approach is better for users who already know GraphQL and want full control. monday_ruby prioritizes ease of use for Ruby developers who may not know GraphQL.

### Alternative 2: REST-Style Interface

The gem could mimic REST APIs:

```ruby
client = Monday::Client.new(token: "...")
boards = client.get("/boards", params: {ids: [123]})
item = client.post("/items", body: {name: "New Item", board_id: 456})
```

**Trade-offs:**
- ✅ Familiar to REST API users
- ✅ Simple HTTP-style interface
- ❌ Doesn't match monday.com's GraphQL nature
- ❌ Hard to represent nested field selection
- ❌ Inefficient data fetching (over-fetching or under-fetching)

This works well for REST APIs but fights against GraphQL's strength of precise data fetching.

### Alternative 3: Active Record Pattern

The gem could model monday.com resources as ActiveRecord-style objects:

```ruby
board = Monday::Board.find(123)
board.name = "New Name"
board.save

item = board.items.create(name: "New Item")
```

**Trade-offs:**
- ✅ Familiar to Rails developers
- ✅ Object-oriented interface
- ❌ Implies more than the API provides (no change tracking, associations, etc.)
- ❌ Requires maintaining object state
- ❌ Hides GraphQL's explicit field selection
- ❌ More complex implementation

While appealing, this pattern doesn't fit monday.com's API model. The API is query-based, not CRUD-based, and doesn't support partial updates or lazy loading the way ActiveRecord expects.

### The Chosen Approach

monday_ruby's client-resource pattern strikes a balance:

- More accessible than raw GraphQL (Ruby methods vs. query strings)
- More powerful than REST-style (explicit field selection, complex queries)
- Simpler than ActiveRecord (stateless, explicit requests)
- Flexible enough to support monday.com's evolving API

The design prioritizes:
1. **Ease of use** for developers new to monday.com or GraphQL
2. **Explicit behavior** over magic (you call methods, get responses)
3. **Extensibility** (easy to add resources and methods)
4. **Transparency** (clear what queries are being executed)

## Conclusion

The monday_ruby architecture emerged from practical constraints and design goals:

- **Client-Resource Pattern**: Organizes code around monday.com's domain model
- **Dynamic Resource Initialization**: Enables automatic registration and consistent naming
- **String-Based Query Building**: Balances simplicity with flexibility
- **Layered Request Flow**: Separates concerns while maintaining clarity
- **Robust Error Handling**: Deals with monday.com's varied error formats

These decisions create a gem that feels natural to Ruby developers while effectively wrapping a complex GraphQL API. The architecture isn't the only way to solve this problem, but it's well-suited to the gem's goals of accessibility, maintainability, and power.
