# Configuration

Manage global and client-specific configuration for the monday_ruby gem.

## Overview

The `Monday::Configuration` class controls how the gem connects to the monday.com API. You can set configuration globally for all clients or customize it per-client instance.

## Configuration Options

All configuration options with their types, defaults, and descriptions:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `token` | String | `nil` | API authentication token (required for all requests) |
| `host` | String | `"https://api.monday.com/v2"` | monday.com API endpoint URL |
| `version` | String | `"2023-07"` | API version to use (format: YYYY-MM) |
| `open_timeout` | Integer | `10` | Seconds to wait for connection to open |
| `read_timeout` | Integer | `30` | Seconds to wait for response data |

## Global Configuration

Configure once and use across all clients:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
  config.version = "2024-10"
  config.open_timeout = 15
  config.read_timeout = 60
end

# All clients use global configuration
client = Monday::Client.new
response = client.boards
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>When to Use Global Configuration</span>
Use global configuration when your application uses a single monday.com account. This is the most common scenario.
:::

### Accessing Global Config

Read global configuration values:

```ruby
Monday.configure do |config|
  config.token = "my_token"
  config.version = "2024-10"
end

# Access global config
puts Monday.config.token    # => "my_token"
puts Monday.config.version  # => "2024-10"
puts Monday.config.host     # => "https://api.monday.com/v2"
```

## Instance Configuration

Configure individual clients with different settings:

```ruby
require "monday_ruby"

# Client A with token A
client_a = Monday::Client.new(
  token: ENV["MONDAY_TOKEN_A"],
  version: "2024-10"
)

# Client B with token B and longer timeouts
client_b = Monday::Client.new(
  token: ENV["MONDAY_TOKEN_B"],
  version: "2024-01",
  read_timeout: 120
)

# Each client uses its own configuration
response_a = client_a.boards
response_b = client_b.boards
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>When to Use Instance Configuration</span>
Use instance configuration for multi-tenant applications or when connecting to multiple monday.com accounts simultaneously.
:::

### Accessing Instance Config

Read instance-specific configuration:

```ruby
client = Monday::Client.new(
  token: "my_token",
  version: "2024-10"
)

# Access client's config
puts client.config.token    # => "my_token"
puts client.config.version  # => "2024-10"
```

## Methods

### initialize

Creates a new configuration instance with optional parameters.

```ruby
config = Monday::Configuration.new(
  token: "your_token",
  version: "2024-10",
  open_timeout: 15,
  read_timeout: 60
)
```

**Parameters:**

- `token` (String, optional) - API authentication token
- `host` (String, optional) - API endpoint URL
- `version` (String, optional) - API version
- `open_timeout` (Integer, optional) - Connection timeout in seconds
- `read_timeout` (Integer, optional) - Response timeout in seconds

**Raises:**

- `ArgumentError` - When invalid configuration keys are provided

**Example:**

```ruby
# Valid configuration
config = Monday::Configuration.new(token: "abc123")

# Invalid configuration (raises ArgumentError)
config = Monday::Configuration.new(invalid_key: "value")
# => ArgumentError: Unknown arguments: [:invalid_key]
```

### reset

Resets all configuration values to their defaults.

```ruby
Monday.configure do |config|
  config.token = "my_token"
  config.version = "2024-10"
end

Monday.config.reset

puts Monday.config.token   # => nil
puts Monday.config.version # => "2023-07"
```

**Note:** This method is typically used in test environments to ensure clean state between tests.

### Attribute Accessors

All configuration fields have getter and setter methods:

```ruby
config = Monday::Configuration.new

# Setters
config.token = "new_token"
config.version = "2024-10"
config.host = "https://custom.monday.com/v2"
config.open_timeout = 20
config.read_timeout = 90

# Getters
config.token        # => "new_token"
config.version      # => "2024-10"
config.host         # => "https://custom.monday.com/v2"
config.open_timeout # => 20
config.read_timeout # => 90
```

## API Versions

The `version` parameter specifies which monday.com API version to use.

### Available Versions

monday.com uses dated API versions in `YYYY-MM` format:

- `"2024-10"` - October 2024 version
- `"2024-01"` - January 2024 version
- `"2023-10"` - October 2023 version
- `"2023-07"` - July 2023 version (default)

### Setting API Version

**Global:**

```ruby
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
  config.version = "2024-10"
end
```

**Per-Client:**

```ruby
client = Monday::Client.new(
  token: ENV["MONDAY_TOKEN"],
  version: "2024-10"
)
```

### Version Usage

The version is sent in the `API-Version` header with every request:

```ruby
# Internally, requests include:
# Headers:
#   Authorization: your_token
#   API-Version: 2024-10
```

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Breaking Changes</span>
API versions may introduce breaking changes. Test thoroughly before upgrading to a new version.
:::

### Finding Available Versions

See [monday.com's API versioning documentation](https://developer.monday.com/api-reference/docs/api-versioning) for the complete list of available versions and their changes.

## Timeouts

Control how long the gem waits for API responses.

### open_timeout

Maximum seconds to wait while establishing a connection to monday.com's API.

**Default:** `10` seconds

**When to Increase:**
- Slow network connections
- Connecting through proxies
- High-latency environments

**Example:**

```ruby
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
  config.open_timeout = 20  # Wait up to 20 seconds to connect
end
```

### read_timeout

Maximum seconds to wait for the API to return a response after the connection is established.

**Default:** `30` seconds

**When to Increase:**
- Large data exports
- Complex queries with many boards/items
- Bulk operations
- Known slow endpoints

**Example:**

```ruby
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
  config.read_timeout = 120  # Wait up to 2 minutes for response
end
```

### Timeout Behavior

When a timeout is exceeded, a timeout error is raised:

```ruby
client = Monday::Client.new(
  token: ENV["MONDAY_TOKEN"],
  read_timeout: 5  # Very short timeout
)

begin
  # Large query that takes more than 5 seconds
  response = client.boards.query(
    args: { limit: 1000 },
    select: ["id", "name", "items { id name }"]
  )
rescue Net::ReadTimeout => e
  puts "Request timed out: #{e.message}"
  # Retry with longer timeout or smaller query
end
```

## Usage Examples

### Development Environment

```ruby
# config/initializers/monday.rb (Rails)
# or at the top of your script

require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
  config.version = "2024-10"
  config.read_timeout = 60  # Longer timeout for complex queries
end
```

### Production Environment

**Using Rails Credentials:**

```ruby
# config/initializers/monday.rb
Monday.configure do |config|
  config.token = Rails.application.credentials.monday[:token]
  config.version = Rails.application.credentials.monday[:version] || "2024-10"
  config.open_timeout = 15
  config.read_timeout = 90
end
```

**Using Environment Variables:**

```ruby
Monday.configure do |config|
  config.token = ENV.fetch("MONDAY_TOKEN")
  config.version = ENV.fetch("MONDAY_API_VERSION", "2024-10")
  config.open_timeout = ENV.fetch("MONDAY_OPEN_TIMEOUT", 10).to_i
  config.read_timeout = ENV.fetch("MONDAY_READ_TIMEOUT", 30).to_i
end
```

### Multi-Tenant Application

Handle multiple monday.com accounts:

```ruby
class MondayService
  def initialize(user)
    @client = Monday::Client.new(
      token: user.monday_token,
      version: user.monday_api_version || "2024-10"
    )
  end

  def fetch_boards
    @client.boards.query(
      select: ["id", "name", "workspace_id"]
    )
  end
end

# Usage
service = MondayService.new(current_user)
response = service.fetch_boards
```

### Testing Environment

Reset configuration between tests:

```ruby
# spec/spec_helper.rb or test/test_helper.rb
RSpec.configure do |config|
  config.before(:each) do
    Monday.config.reset
    Monday.configure do |c|
      c.token = "test_token"
      c.version = "2024-10"
    end
  end
end
```

### Custom API Host

For testing or custom deployments:

```ruby
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
  config.host = "https://staging.monday.com/v2"  # Custom endpoint
  config.version = "2024-10"
end
```

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Custom Host Usage</span>
Changing the `host` is rarely needed. Only modify this if you're connecting to a custom monday.com deployment or testing environment.
:::

### Dynamic Configuration

Change configuration at runtime:

```ruby
# Start with default config
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN_DEFAULT"]
end

client = Monday::Client.new

# Later, switch to different account
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN_PREMIUM"]
end

# New clients use updated config
premium_client = Monday::Client.new
```

## Best Practices

### Store Tokens Securely

Never hardcode tokens in your source code:

```ruby
# Bad - Token in code
Monday.configure do |config|
  config.token = "eyJhbGc..."  # Never do this!
end

# Good - Token from environment
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

# Better - Validate token exists
Monday.configure do |config|
  config.token = ENV.fetch("MONDAY_TOKEN") do
    raise "MONDAY_TOKEN environment variable not set"
  end
end
```

### Use Environment-Specific Configuration

Separate configuration by environment:

```ruby
# config/initializers/monday.rb
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]

  case Rails.env
  when "development"
    config.read_timeout = 120  # Longer timeout for debugging
  when "test"
    config.token = "test_token"
  when "production"
    config.open_timeout = 10
    config.read_timeout = 60
    config.version = "2024-10"
  end
end
```

### Validate Configuration on Startup

Ensure configuration is valid before running:

```ruby
def validate_configuration!
  raise "MONDAY_TOKEN not configured" if Monday.config.token.nil?

  client = Monday::Client.new
  response = client.account.query(select: ["id"])

  unless response.success?
    raise "Invalid monday.com configuration: #{response.code}"
  end

  puts "monday.com configuration valid"
end

# Call during application startup
validate_configuration!
```

### Document Configuration Requirements

Add a `.env.example` file to your project:

```bash
# .env.example
# monday.com API Configuration
MONDAY_TOKEN=your_token_here
MONDAY_API_VERSION=2024-10
MONDAY_READ_TIMEOUT=60
```

### Use Defaults When Appropriate

Only override defaults when necessary:

```ruby
# Minimal configuration (uses defaults for everything else)
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

# Override only what you need
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
  config.read_timeout = 120  # Only change this
end
```

## Constants

### DEFAULT_HOST

Default monday.com API endpoint:

```ruby
Monday::Configuration::DEFAULT_HOST
# => "https://api.monday.com/v2"
```

### DEFAULT_TOKEN

Default token value (nil):

```ruby
Monday::Configuration::DEFAULT_TOKEN
# => nil
```

### DEFAULT_VERSION

Default API version:

```ruby
Monday::Configuration::DEFAULT_VERSION
# => "2023-07"
```

### DEFAULT_OPEN_TIMEOUT

Default connection timeout in seconds:

```ruby
Monday::Configuration::DEFAULT_OPEN_TIMEOUT
# => 10
```

### DEFAULT_READ_TIMEOUT

Default read timeout in seconds:

```ruby
Monday::Configuration::DEFAULT_READ_TIMEOUT
# => 30
```

### CONFIGURATION_FIELDS

Array of valid configuration field names:

```ruby
Monday::Configuration::CONFIGURATION_FIELDS
# => [:token, :host, :version, :open_timeout, :read_timeout]
```

## Related Documentation

- [Client](/reference/client) - Client initialization and usage
- [Authentication](/guides/authentication) - Token management and security
- [Installation](/guides/installation) - Initial setup
- [Error Handling](/guides/advanced/errors) - Handling configuration errors

## External References

- [monday.com API Versioning](https://developer.monday.com/api-reference/docs/api-versioning)
- [monday.com Developer Center](https://developer.monday.com/)
