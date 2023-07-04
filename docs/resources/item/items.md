# #items

Querying `items` will return the metadata for one or a collection of columns.

### Basic usage

This method accepts various arguments to fetch the items. You can find the complete list of arguments [here](https://developer.monday.com/api-reference/docs/items#arguments).

You can pass these filters using the `args` option.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  ids: [1234, 5678]
}
response = client.items(args: args)

puts response.body
```
{% endcode %}

This will return the items' ID, name and created\_at fields by default.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "items": [
      {
        "id": "1234",
        "name": "Task 1",
        "created_at": "2023-06-26T23:20:56Z"
      },
      "items": [
      {
        "id": "5678",
        "name": "Task 2",
        "created_at": "2023-06-26T23:25:50Z"
      }
    ]
  },
  "account_id": 123
}
```
{% endcode %}

### Customizing fields to retrieve

You can customize the fields to retrieve by passing in the `select` option and listing all the fields you need to retrieve as an array.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  ids: [1234, 5678]
}
select = %w[id state creator_id]
response = client.items(args: args, select: select)

puts response.body
```
{% endcode %}

### Retrieving nested fields

Some fields have nested attributes, and you need to specify the attributes to retrieve that field; else, the API will respond with an error. For example, the field `creator` is of type `User` and expects you to pass the attributes from `User` that you want to retrieve for `creator`.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  ids: [1234, 5678]
}
select = [
  "id",
  "state",
  "creator_id",
  {
    creator: %w[id name email is_admin]
  }
]

response = client.items(args: args, select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for items [here](https://developer.monday.com/api-reference/docs/items#fields).
