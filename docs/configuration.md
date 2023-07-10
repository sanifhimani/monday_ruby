# Configuration

To interact with the API, you must provide a valid auth token. This token can be generated from the Administration tab on the account. For more authentication information, please look at monday.com's [API documentation](https://developer.monday.com/api-reference/docs/authentication).

Once you have the authentication token, you can either globally configure the library or you can configure a specific client.

### Global

To configure the library globally, you can do the following:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = <AUTH_TOKEN>
end
```

### Client specific config

To configure a client, you can do the following:

```ruby
require "monday_ruby"

client = Monday::Client.new(token: <AUTH_TOKEN>)
```
