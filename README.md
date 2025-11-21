# monday_ruby

![Build Status](https://github.com/sanifhimani/monday_ruby/actions/workflows/ci.yml/badge.svg)
[![Gem Version](https://badge.fury.io/rb/monday_ruby.svg)](https://badge.fury.io/rb/monday_ruby)
[![Coverage Status](https://coveralls.io/repos/github/sanifhimani/monday_ruby/badge.svg?branch=main)](https://coveralls.io/github/sanifhimani/monday_ruby?branch=main)

A Ruby client library for the [monday.com GraphQL API](https://developer.monday.com/api-reference). Build integrations with boards, items, columns, and more using idiomatic Ruby.

## Features

- **Resource-based API** - Clean, intuitive interface (`client.board.query`, `client.item.create`)
- **Flexible configuration** - Global or per-client setup
- **Comprehensive error handling** - Typed exceptions for different error scenarios
- **Cursor-based pagination** - Efficiently handle large datasets
- **Fully tested** - 100% test coverage with VCR-recorded fixtures

## Documentation

**[Complete Documentation →](https://sanifhimani.github.io/monday_ruby/)**

- [Getting Started Tutorial](https://sanifhimani.github.io/monday_ruby/tutorial/first-integration)
- [How-to Guides](https://sanifhimani.github.io/monday_ruby/guides/installation)
- [API Reference](https://sanifhimani.github.io/monday_ruby/reference/client)
- [Best Practices](https://sanifhimani.github.io/monday_ruby/explanation/best-practices/errors)

## Installation

Add to your Gemfile:

```ruby
gem "monday_ruby"
```

Or install directly:

```bash
gem install monday_ruby
```

## Quick Start

```ruby
require "monday_ruby"

# Configure with your API token
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

# Create a client
client = Monday::Client.new

# Query boards
response = client.board.query(args: { limit: 5 })

if response.success?
  boards = response.body.dig("data", "boards")
  boards.each { |board| puts board["name"] }
end
```

Get your API token from your [monday.com Admin settings](https://support.monday.com/hc/en-us/articles/360005144659-Does-monday-com-have-an-API).

## Usage

### Configuration

**Global configuration** (recommended):

```ruby
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
  config.version = "2024-01"  # API version (optional)
end

client = Monday::Client.new
```

**Per-client configuration**:

```ruby
client = Monday::Client.new(
  token: ENV["MONDAY_TOKEN"],
  version: "2024-01"
)
```

**Configure timeouts**:

```ruby
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
  config.open_timeout = 10  # seconds (default: 10)
  config.read_timeout = 30  # seconds (default: 30)
end
```

### Working with Boards

```ruby
# Query boards
response = client.board.query(
  args: { ids: [1234567890] },
  select: ["id", "name", "description"]
)

boards = response.body.dig("data", "boards")

# Create a board
response = client.board.create(
  args: {
    board_name: "Project Tasks",
    board_kind: "public",
    description: "Track project deliverables"
  }
)

board = response.body.dig("data", "create_board")
```

### Working with Items

```ruby
# Create an item
response = client.item.create(
  args: {
    board_id: 1234567890,
    item_name: "Implement authentication",
    column_values: {
      status: { label: "Working on it" },
      date4: { date: "2024-12-31" }
    }
  }
)

# Query items
response = client.item.query(
  args: { ids: [987654321] },
  select: ["id", "name", { column_values: ["id", "text"] }]
)

items = response.body.dig("data", "items")
```

### Pagination

Handle large datasets efficiently with cursor-based pagination:

```ruby
# Fetch first page
response = client.board.items_page(
  board_ids: 1234567890,
  limit: 100
)

items = response.body.dig("data", "boards", 0, "items_page", "items")
cursor = response.body.dig("data", "boards", 0, "items_page", "cursor")

# Fetch next page
if cursor
  next_response = client.board.items_page(
    board_ids: 1234567890,
    limit: 100,
    cursor: cursor
  )
end
```

See the [Pagination Guide](https://sanifhimani.github.io/monday_ruby/guides/advanced/pagination) for more details.

### Error Handling

The library provides typed exceptions for different error scenarios:

```ruby
begin
  response = client.board.query(args: { ids: [123] })
rescue Monday::AuthorizationError => e
  puts "Invalid API token: #{e.message}"
rescue Monday::InvalidRequestError => e
  puts "Invalid request: #{e.message}"
rescue Monday::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
rescue Monday::Error => e
  puts "API error: #{e.message}"
end
```

See the [Error Handling Guide](https://sanifhimani.github.io/monday_ruby/guides/advanced/errors) for best practices.

## Available Resources

The client provides access to all monday.com resources:

- **Boards** - `client.board`
- **Items** - `client.item`
- **Columns** - `client.column`
- **Files** - `client.file`
- **Groups** - `client.group`
- **Updates** - `client.update`
- **Subitems** - `client.subitem`
- **Workspaces** - `client.workspace`
- **Folders** - `client.folder`
- **Account** - `client.account`
- **Activity Logs** - `client.activity_log`
- **Board Views** - `client.board_view`

For complete API documentation, see the [API Reference](https://sanifhimani.github.io/monday_ruby/reference/client).

## Development

### Running Tests

```bash
bundle exec rake spec
```

Tests use [VCR](https://github.com/vcr/vcr) to record HTTP interactions, so you don't need a monday.com API token to run them.

### Linting

```bash
bundle exec rake rubocop
```

### All Checks

```bash
bundle exec rake  # Runs both tests and linter
```

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/sanifhimani/monday_ruby).

Please read our [Contributing Guide](CONTRIBUTING.md) for details on:
- Development setup and testing
- Documentation guidelines
- Code style and commit conventions

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
