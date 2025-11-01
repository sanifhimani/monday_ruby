# monday_ruby

A Ruby client library for the monday.com GraphQL API.

## Installation

```bash
gem install monday_ruby
```

Or add to your Gemfile:

```ruby
gem 'monday_ruby'
```

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

### New to monday_ruby?

**[Start with the tutorial →](/tutorial/first-integration)**

Learn by building your first monday.com integration. Takes about 15 minutes.

### Looking for specific solutions?

**[Browse how-to guides →](/guides/installation)**

Task-based guides for common scenarios: creating boards, managing items, handling pagination, and more.

### Need API details?

**[Check the API reference →](/reference/client)**

Complete documentation for all resources, methods, parameters, and return values.

---

## Requirements

- Ruby 2.7 or higher
- A monday.com account with API access
- A monday.com API token

## Resources

- [GitHub Repository](https://github.com/sanifhimani/monday_ruby)
- [RubyGems Package](https://rubygems.org/gems/monday_ruby)
- [monday.com API Documentation](https://developer.monday.com/api-reference/docs)
- [Report an Issue](https://github.com/sanifhimani/monday_ruby/issues)

## Support

Need help? Check the [how-to guides](/guides/installation) or [open an issue](https://github.com/sanifhimani/monday_ruby/issues) on GitHub.
