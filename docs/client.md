# Client

The Monday client is flat, meaning most API actions are available as methods on the client object. To initialize a client, run the following:

{% code lineNumbers="true" %}
```ruby
# If the library is configured globally
client_with_global_config = Monday::Client.new

# For a specific client
client = Monday::Client.new(token: <AUTH_TOKEN>)
```
{% endcode %}

You can then use all the [resources](resources/) using the client object.
