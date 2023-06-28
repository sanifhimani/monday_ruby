# Monday API Library for Ruby

![Build Status](https://github.com/sanifhimani/monday-ruby/actions/workflows/ci.yml/badge.svg)

This library provides convenient access to the Monday.com API from the application written in the Ruby language. It includes a pre-defined set of actions for the API resources.

The library also provides an easy configuration path for quick setup and use.

**Visit https://monday-ruby.gitbook.io/docs/ for detailed documentation on how to use the library.**

## Installation

You don't need the source code unless you want to modify the gem. If you want to use the package, run:

```sh
gem install monday-ruby
```

If you want to build the gem from source:

```sh
gem build monday-ruby.gemspec
```

### Requirements

* Ruby 2.6+

### Bundler

If you are installing via bundler, you should be sure to use the https rubygems source in your Gemfile, as any gems fetched over http could potentially be compromised in transit and alter the code of gems fetched securely over https:

```ruby
source "https://rubygems.org"

gem "monday-ruby"
```

## Usage

***Complete list of actions along with examples are provided [here](https://monday-ruby.gitbook.io/docs/).***

The library needs to be configured with your account's authentication token which is available on the Admin tab on monday.com. Elaborate documentation can be found [here](https://developer.monday.com/api-reference/docs/authentication).

```ruby
require "monday-ruby"

Monday.configure do |config|
  config.token = "<AUTH_TOKEN>"
end
```

You can also configure the auth token on the client directly:

```ruby
require "monday-ruby"

client = Monday::Client.new(token: "<AUTH_TOKEN>")
```

### Accessing a response object

Get access to response objects by initializing a client and using the appropriate action you want to perform:

```ruby
client = Monday::Client.new
response = client.boards

puts response.body
```

### Use cases

Here are some common uses cases for the API client.

#### Fetching all the boards

Initialize the client with the auth token and call the `boards` action.

```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

response = client.boards
# => <Monday::Response ...>

# To check if the request was successful
response.success?
# => true

# To get the boards from the response
response.dig("data", "boards")
# => [...]
```

#### Creating a new board

Initialize the client with the auth token and call the `create_board` action.

```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  board_name: "Test board",
  board_kind: "public",
  description: "Test board description"
}

response = client.create_board(args: args)
# => <Monday::Response ...>

# To check if the request was successful
response.success?
# => true

# To get the created board from the response
response.dig("data", "create_board")
# => { ... }
```

#### Creating a new item on board

Initialize the client with the auth token and call the `create_item` action.

```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  board_id: <BOARD_ID>,
  item_name: "New item",
  column_values: {
    status: {
      label: "Working on it"
    },
    keywords: {
      labels: ["Tech team", "DevOps team"]
    }
  }
}

response = client.create_item(args: args)
# => <Monday::Response ...>

# To check if the request was successful
response.success?
# => true

# To get the created item from the response
response.dig("data", "create_item")
# => { ... }
```

## Development

Run all tests:

```sh
bundle exec rake spec
```

Run linter:

```sh
bundle exec rake rubocop
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sanifhimani/monday-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/sanifhimani/monday-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
