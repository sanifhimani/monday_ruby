# #duplicate\_board

The `duplicate_board` mutation will allow you to duplicate a board with all its items and groups to a workspace or folder of your choice.

### Basic usage

This method accepts various arguments to duplicate a board. You can find the complete list of arguments [here](https://developer.monday.com/api-reference/docs/boards#arguments-2).

You can pass these filters using the `args` option.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  board_id: 456,
  duplicate_type: "duplicate_board_with_structure"
}
response = client.duplicate_board(args: args)

puts response.body
```
{% endcode %}

This will duplicate the board `456`.

This will return the boards' ID, name and description fields by default.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "duplicate_board": {
      "board": {
        "id": "789",
        "name": "Duplicate of New test board",
        "description": "The description for the board"
      }
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
  board_id: 456,
  duplicate_type: "duplicate_board_with_structure"
}
select = %w[id name description items_count permissions]

response = client.duplicate_board(args: args, select: select)

puts response.body
```
{% endcode %}

### Retrieving nested fields

Some fields have nested attributes, and you need to specify the attributes to retrieve that field; else, the API will respond with an error.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  board_id: 456,
  duplicate_type: "duplicate_board_with_structure"
}
select = [
  "id",
  "name",
  {
    creator: %w[id name email is_admin]
  }
]

response = client.duplicate_board(args: args, select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for boards [here](https://developer.monday.com/api-reference/docs/board-view-queries#fields).
