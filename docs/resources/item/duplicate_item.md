# #duplicate\_item

The `duplicate_item` mutation will allow you to duplicate an item.

### Basic usage

This method accepts three required arguments - `board_id`, `item_id` and `with_updates`.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

board_id = "123"
item_id = "7890"
with_updates = true
response = client.duplicate_item(board_id, item_id, with_updates)

puts response.body
```
{% endcode %}

This will return the items' ID, name and created\_at fields by default.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "duplicate_item": {
      "id": "0123",
      "name": "New Task (copy)",
      "created_at": "2023-06-27T16:45:07Z"
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

board_id = "123"
item_id = "7890"
with_updates = true

select = %w[id state creator_id]
response = client.duplicate_item(board_id, item_id, with_updates, select: select)

puts response.body
```
{% endcode %}

### Retrieving nested fields

Some fields have nested attributes, and you need to specify the attributes to retrieve that field; else, the API will respond with an error. For example, the field `creator` is of type `User` and expects you to pass the attributes from `User` that you want to retrieve for `creator`.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

board_id = "123"
item_id = "7890"
with_updates = true

select = [
  "id",
  "state",
  "creator_id",
  {
    creator: %w[id name email is_admin]
  }
]

response = client.duplicate_item(board_id, item_id, with_updates, select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for items [here](https://developer.monday.com/api-reference/docs/items#fields).
