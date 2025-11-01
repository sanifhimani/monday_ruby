# Client

The `Monday::Client` class is the main entry point for interacting with the monday.com API. It handles authentication, request execution, error handling, and provides access to all resource classes.

## Overview

The Client class:

- Manages authentication and configuration
- Executes GraphQL queries and mutations via HTTP requests
- Automatically initializes all resource objects (boards, items, groups, etc.)
- Handles response parsing and error mapping
- Provides both global and instance-level configuration

## Initialization

### Basic Usage

Create a client instance with your API token:

```ruby
require "monday_ruby"

# Using instance configuration
client = Monday::Client.new(token: "your_api_token_here")
```

### Global Configuration

Set up configuration once and reuse across multiple client instances:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = "your_api_token_here"
  config.version = "2023-07"
  config.open_timeout = 10
  config.read_timeout = 30
end

# Uses global configuration
client = Monday::Client.new
```

### Instance Configuration

Override global configuration for specific client instances:

```ruby
# Global config
Monday.configure do |config|
  config.token = "default_token"
end

# Instance config (overrides global)
client = Monday::Client.new(
  token: "different_token",
  version: "2024-01",
  open_timeout: 15,
  read_timeout: 45
)
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `token` | String | `nil` | monday.com API authentication token (required) |
| `host` | String | `"https://api.monday.com/v2"` | API endpoint URL |
| `version` | String | `"2023-07"` | API version to use |
| `open_timeout` | Integer | `10` | Connection timeout in seconds |
| `read_timeout` | Integer | `30` | Read timeout in seconds |

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Getting Your API Token</span>
Find your API token in your monday.com account under **Admin** → **API**. See the [Authentication guide](/guides/authentication) for detailed instructions.
:::

## Available Resources

The client provides access to all monday.com resources through dynamically initialized resource objects. Each resource is automatically created when you initialize a client.

### Accessing Resources

```ruby
client = Monday::Client.new(token: "your_token")

# Access resources via client instance
client.account       # => Monday::Resources::Account
client.activity_log  # => Monday::Resources::ActivityLog
client.board         # => Monday::Resources::Board
client.board_view    # => Monday::Resources::BoardView
client.column        # => Monday::Resources::Column
client.folder        # => Monday::Resources::Folder
client.group         # => Monday::Resources::Group
client.item          # => Monday::Resources::Item
client.subitem       # => Monday::Resources::Subitem
client.update        # => Monday::Resources::Update
client.workspace     # => Monday::Resources::Workspace
```

### Resource Summary

| Resource | Description | Documentation |
|----------|-------------|---------------|
| **account** | Query account information and users | [Account Reference](/reference/resources/account) |
| **activity_log** | Retrieve activity logs and audit trail | [Activity Log Reference](/reference/resources/activity-log) |
| **board** | Create, query, update, and manage boards | [Board Reference](/reference/resources/board) |
| **board_view** | Access and configure board views | [Board View Reference](/reference/resources/board-view) |
| **column** | Create and modify board columns | [Column Reference](/reference/resources/column) |
| **folder** | Organize boards into folders | [Folder Reference](/reference/resources/folder) |
| **group** | Manage board groups | [Group Reference](/reference/resources/group) |
| **item** | Create, query, and update items | [Item Reference](/reference/resources/item) |
| **subitem** | Work with subitems | [Subitem Reference](/reference/resources/subitem) |
| **update** | Post and retrieve updates | [Update Reference](/reference/resources/update) |
| **workspace** | Manage workspaces | [Workspace Reference](/reference/resources/workspace) |

## Public Methods

### config

```ruby
client.config # => Monday::Configuration
```

Returns the configuration object associated with this client instance.

**Returns:** `Monday::Configuration`

**Example:**

```ruby
client = Monday::Client.new(token: "your_token", version: "2023-07")

config = client.config
config.token   # => "your_token"
config.version # => "2023-07"
config.host    # => "https://api.monday.com/v2"
```

## Usage Examples

### Basic Query

Query boards using the client:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: "your_token")

# Query boards
response = client.board.query(
  args: { ids: [123, 456] },
  select: ["id", "name", "description"]
)

if response.success?
  boards = response.body.dig("data", "boards")
  boards.each do |board|
    puts "Board: #{board["name"]}"
  end
end
```

### Creating Resources

Use mutation methods to create new resources:

```ruby
client = Monday::Client.new(token: "your_token")

# Create a new board
response = client.board.create(
  args: {
    board_name: "Project Board",
    board_kind: :public
  },
  select: ["id", "name"]
)

board = response.body.dig("data", "create_board")
puts "Created board #{board["name"]} with ID: #{board["id"]}"

# Create an item on the board
item_response = client.item.create(
  args: {
    board_id: board["id"],
    item_name: "First Task"
  },
  select: ["id", "name"]
)

item = item_response.body.dig("data", "create_item")
puts "Created item: #{item["name"]}"
```

### Complex Nested Queries

Query boards with nested data:

```ruby
client = Monday::Client.new(token: "your_token")

response = client.board.query(
  args: { ids: [123] },
  select: [
    "id",
    "name",
    {
      groups: [
        "id",
        "title",
        {
          items: [
            "id",
            "name",
            {
              column_values: ["id", "text", "value"]
            }
          ]
        }
      ]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "boards", 0)
  board["groups"].each do |group|
    puts "Group: #{group["title"]}"
    group["items"].each do |item|
      puts "  Item: #{item["name"]}"
    end
  end
end
```

### Using Multiple Clients

Create multiple clients for different accounts or configurations:

```ruby
# Production client
prod_client = Monday::Client.new(
  token: ENV["MONDAY_PROD_TOKEN"],
  read_timeout: 60
)

# Sandbox client
sandbox_client = Monday::Client.new(
  token: ENV["MONDAY_SANDBOX_TOKEN"],
  host: "https://api.sandbox.monday.com/v2"
)

# Use different clients independently
prod_boards = prod_client.board.query
sandbox_boards = sandbox_client.board.query
```

### Pagination Example

Use cursor-based pagination for large datasets:

```ruby
client = Monday::Client.new(token: "your_token")

all_items = []
cursor = nil

loop do
  response = client.board.items_page(
    board_ids: 123,
    limit: 100,
    cursor: cursor
  )

  items_page = response.body.dig("data", "boards", 0, "items_page")
  all_items.concat(items_page["items"])

  cursor = items_page["cursor"]
  break if cursor.nil?
end

puts "Retrieved #{all_items.length} total items"
```

## Error Handling

The Client class automatically handles errors and raises appropriate exceptions based on HTTP status codes and GraphQL error codes.

### Exception Hierarchy

All exceptions inherit from `Monday::Error`:

```ruby
Monday::Error (base class)
├── Monday::AuthorizationError (401, 403)
├── Monday::InvalidRequestError (400)
├── Monday::ResourceNotFoundError (404)
├── Monday::InternalServerError (500)
├── Monday::RateLimitError (429)
└── Monday::ComplexityError (GraphQL complexity limit)
```

### Basic Error Handling

```ruby
client = Monday::Client.new(token: "your_token")

begin
  response = client.board.query(args: { ids: [123] })
  boards = response.body.dig("data", "boards")
rescue Monday::AuthorizationError => e
  puts "Authentication failed: #{e.message}"
  puts "Check your API token"
rescue Monday::InvalidRequestError => e
  puts "Invalid request: #{e.message}"
  puts "Error code: #{e.code}"
rescue Monday::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
  sleep 60
  retry
rescue Monday::Error => e
  puts "monday.com API error: #{e.message}"
  puts "Response: #{e.response.body}"
end
```

### Checking Response Success

Alternatively, check `response.success?` before processing:

```ruby
response = client.item.create(
  args: {
    board_id: 123,
    item_name: "New Task"
  }
)

if response.success?
  item = response.body.dig("data", "create_item")
  puts "Created item: #{item["id"]}"
else
  puts "Request failed"
  puts "Status: #{response.status}"
  puts "Error: #{response.body["error_message"]}"
end
```

### Error Properties

All error objects provide:

```ruby
begin
  client.board.query(args: { ids: [999999] })
rescue Monday::Error => e
  e.message    # => "ResourceNotFoundException: Board not found"
  e.code       # => "ResourceNotFoundException"
  e.response   # => Monday::Response object
  e.error_data # => Additional error metadata (hash)
end
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Learn More About Error Handling</span>
See the [Error Handling guide](/guides/advanced/errors) for comprehensive examples, retry strategies, and best practices.
:::

## Best Practices

### Use Global Configuration for Simple Applications

For most applications, global configuration is the simplest approach:

```ruby
# config/initializers/monday.rb (Rails)
Monday.configure do |config|
  config.token = ENV["MONDAY_API_TOKEN"]
  config.version = "2023-07"
end

# Anywhere in your app
client = Monday::Client.new
response = client.board.query
```

### Use Instance Configuration for Multi-Account Applications

When working with multiple monday.com accounts:

```ruby
class MondayService
  def initialize(account_token)
    @client = Monday::Client.new(token: account_token)
  end

  def fetch_boards
    @client.board.query
  end
end

# Use different clients
customer_a = MondayService.new(ENV["CUSTOMER_A_TOKEN"])
customer_b = MondayService.new(ENV["CUSTOMER_B_TOKEN"])
```

### Implement the Singleton Pattern

Reuse a single client instance to reduce overhead:

```ruby
class MondayClient
  def self.instance
    @instance ||= Monday::Client.new(token: ENV["MONDAY_API_TOKEN"])
  end
end

# Use throughout your application
response = MondayClient.instance.board.query
items = MondayClient.instance.item.query
```

### Configure Appropriate Timeouts

Adjust timeouts based on your use case:

```ruby
# For long-running operations (e.g., bulk imports)
client = Monday::Client.new(
  token: "your_token",
  open_timeout: 30,
  read_timeout: 120
)

# For quick, real-time operations
client = Monday::Client.new(
  token: "your_token",
  open_timeout: 5,
  read_timeout: 15
)
```

### Always Handle Errors

Wrap API calls in error handling to prevent application crashes:

```ruby
def create_monday_item(board_id, name)
  client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])

  response = client.item.create(
    args: { board_id: board_id, item_name: name }
  )

  response.body.dig("data", "create_item")
rescue Monday::RateLimitError => e
  # Implement exponential backoff
  sleep 60
  retry
rescue Monday::Error => e
  # Log error and notify
  logger.error("Failed to create monday.com item: #{e.message}")
  notify_error_tracking_service(e)
  nil
end
```

### Check API Version Compatibility

Stay updated with API versions:

```ruby
# Use the latest stable version
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
  config.version = "2024-01" # Update as new versions release
end
```

## Internal Methods

These methods are private and used internally by the client:

- `make_request(body)` - Executes GraphQL requests and returns Response objects
- `configure(config_args)` - Sets up configuration (global or instance)
- `uri` - Builds the API endpoint URI
- `request_headers` - Constructs authentication headers
- `handle_response(response)` - Processes responses and raises errors
- `raise_errors(response)` - Maps errors to exception classes

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Private Methods</span>
These methods are for internal use only. Do not call them directly. Use resource methods instead.
:::

## Response Objects

All client operations return a `Monday::Response` object with the following properties:

```ruby
response = client.board.query(args: { ids: [123] })

response.success?  # => true/false
response.status    # => 200
response.body      # => Hash with parsed JSON response
response.headers   # => Hash with HTTP headers
```

### Response Success Check

The `success?` method returns `true` only when:
1. HTTP status code is 2xx (200-299)
2. Response body does not contain GraphQL errors

```ruby
if response.success?
  # Safe to access data
  data = response.body["data"]
else
  # Handle error
  error = response.body["error_message"]
end
```

## Related Documentation

- [Configuration Reference](/reference/configuration) - Detailed configuration options
- [Response Reference](/reference/response) - Response object structure
- [Error Reference](/reference/errors) - Error classes and codes
- [Authentication Guide](/guides/authentication) - How to get API tokens
- [First Request Guide](/guides/first-request) - Step-by-step tutorial
- [Error Handling Guide](/guides/advanced/errors) - Error handling strategies
- [Rate Limiting Guide](/guides/advanced/rate-limiting) - Handling rate limits

## External References

- [monday.com API Documentation](https://developer.monday.com/api-reference/docs)
- [monday.com Authentication](https://developer.monday.com/api-reference/docs/authentication)
- [GraphQL API Overview](https://developer.monday.com/api-reference/docs/introduction-to-graphql)
