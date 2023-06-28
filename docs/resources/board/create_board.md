# #create\_board

The `create_board` mutation will allow you to create a new board.

### Basic usage

This method accepts various arguments to create a board. You can find the complete list of arguments [here](https://developer.monday.com/api-reference/docs/boards#arguments-1).

You can pass these filters using the `args` option.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  board_name: "New test board",
  board_kind: "public",
  description: "The description for the board"
}
response = client.create_board(args: args)

puts response.body
```
{% endcode %}

This will create a private board with the name "New test board" and description "The description for the board" on the account.

This will return the boards' ID, name and description fields by default.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "create_board": {
      "id": "456",
      "name": "New test board",
      "description": "The description for the board"
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

args = {
  board_name: "New test board",
  board_kind: "public",
  description: "The description for the board"
}
select = %w[id name description items_count permissions]

response = client.create_board(args: args, select: select)

puts response.body
```
{% endcode %}

### Retrieving nested fields

Some fields have nested attributes, and you need to specify the attributes to retrieve that field; else, the API will respond with an error.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  board_name: "New test board",
  board_kind: "public",
  description: "The description for the board"
}
select = [
  "id",
  "name",
  {
    creator: %w[id name email is_admin]
  }
]

response = client.create_board(args: args, select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for boards [here](https://developer.monday.com/api-reference/docs/board-view-queries#fields).
