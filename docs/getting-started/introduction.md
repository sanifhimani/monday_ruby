# Monday Ruby

A Ruby client library for the monday.com GraphQL API.

## Installation

:::code-group
```bash [Terminal]
gem install monday_ruby
```

```ruby [Gemfile]
gem 'monday_ruby'
```
:::

## Quick Example

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new
response = client.boards

boards = response.body.dig("data", "boards")
```

## Documentation

:::cards
::card{title="Getting Started" icon="rocket-launch" href="/getting-started/introduction"}
New to monday_ruby? Start here to get up and running quickly.
::

::card{title="Guides" icon="book-open" href="/guides/installation"}
Task-based guides for creating boards, managing items, handling pagination, and more.
::

::card{title="API Reference" icon="code" href="/reference/core-concepts/client"}
Complete documentation for all resources, methods, parameters, and return values.
::

::card{title="Explanation" icon="info" href="/explanation/architecture"}
Understand how the library works under the hood.
::
:::

## Requirements

- Ruby 2.7 or higher
- A monday.com account with API access
- A monday.com API token

## Resources

- [monday.com API Documentation](https://developer.monday.com/api-reference/docs)
- [Report an Issue](https://github.com/sanifhimani/monday_ruby/issues)
