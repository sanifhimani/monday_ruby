# Client

### Authentication

To interact with the API, you must provide a valid auth token. This token can be generated from the Administration tab on the account. For more authentication information, please look at monday.com's [API documentation](https://developer.monday.com/api-reference/docs/authentication).

Once you have the authentication token, you can add the configuration to the client.

### Client

The Monday client is flat, meaning most API actions are available as methods on the client object. To initialize a client, run the following:

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)
```
{% endcode %}
