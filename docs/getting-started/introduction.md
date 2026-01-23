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
::card{title="Tutorial" icon="graduation-cap" href="/tutorial/first-integration"}
New to monday_ruby? Learn by building your first monday.com integration.
::

::card{title="How-to Guides" icon="book-open" href="/guides/installation"}
Task-based guides for creating boards, managing items, handling pagination, and more.
::

::card{title="API Reference" icon="code" href="/reference/client"}
Complete documentation for all resources, methods, parameters, and return values.
::
:::

## Requirements

- Ruby 2.7 or higher
- A monday.com account with API access
- A monday.com API token

## Resources

- :book: [monday.com API Documentation](https://developer.monday.com/api-reference/docs)
- :bug: [Report an Issue](https://github.com/sanifhimani/monday_ruby/issues)

## Support

Need help? Check the [how-to guides](/guides/installation) or [open an issue](https://github.com/sanifhimani/monday_ruby/issues) on GitHub.
