# #archive\_item

The `archive_item` mutation will allow you to archive an item.

### Basic usage

This method accepts one required argument - `item_id`.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

item_id = "0123"

response = client.archive_item(item_id)

puts response.body
```
{% endcode %}

This will return the archived item's ID by default.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "archive_item": {
      "id": "0123"
    }
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

item_id = "0123"

select = %w[id state creator_id]
response = client.archive_item(item_id, select: select)

puts response.body
```
{% endcode %}

### Retrieving nested fields

Some fields have nested attributes, and you need to specify the attributes to retrieve that field; else, the API will respond with an error. For example, the field `creator` is of type `User` and expects you to pass the attributes from `User` that you want to retrieve for `creator`.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

item_id = "0123"

select = [
  "id",
  "state",
  "creator_id",
  {
    creator: %w[id name email is_admin]
  }
]

response = client.archive_item(item_id, select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for items [here](https://developer.monday.com/api-reference/docs/items#fields).
