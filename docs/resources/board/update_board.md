# #update\_board

The `update_board` mutation will allow you to update a board.

### Basic usage

This method accepts various arguments to duplicate a board. You can find the complete list of arguments [here](https://developer.monday.com/api-reference/docs/boards#arguments-3).

You can pass these filters using the `args` option.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  board_id: 789,
  board_attribute: "description",
  new_value: "Updated description"
}
response = client.update_board(args: args)

puts response.body
```
{% endcode %}

This will update board `789`'s description.

This will return the boards' ID, name and description fields by default.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "update_board": "{\"success\":true,\"undo_data\":{\"undo_record_id\":65894,\"action_type\":\"modify_project\",\"entity_type\":\"Board\",\"entity_id\":789,\"count\":1}}"
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
  board_id: 789,
  board_attribute: "description",
  new_value: "Updated description"
}
select = %w[id name description items_count permissions]

response = client.update_board(args: args, select: select)

puts response.body
```
{% endcode %}

### Retrieving nested fields

Some fields have nested attributes, and you need to specify the attributes to retrieve that field; else, the API will respond with an error.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  board_id: 789,
  board_attribute: "description",
  new_value: "Updated description"
}
select = [
  "id",
  "name",
  {
    creator: %w[id name email is_admin]
  }
]

response = client.update_board(args: args, select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for board views [here](https://developer.monday.com/api-reference/docs/board-view-queries#fields).

{% hint style="info" %}
Visit monday.com's API documentation to know more about the [boards API](https://developer.monday.com/api-reference/docs/boards).
{% endhint %}
