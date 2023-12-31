# #archive\_board

The `archive_board` mutation will allow you to archive a board.

### Basic usage

This method accepts one required argument - `board_id`.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

board_id = 789
response = client.archive_board(board_id)

puts response.body
```
{% endcode %}

This will archive the `789` board.

This will return the board's ID by default.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "archive_board": {
      "id": "789"
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

board_id = 789
select = %w[id name description items_count permissions]

response = client.archive_board(board_id, select: select)

puts response.body
```
{% endcode %}

### Retrieving nested fields

Some fields have nested attributes, and you need to specify the attributes to retrieve that field; else, the API will respond with an error.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

board_id = 789
select = [
  "id",
  "name",
  {
    creator: %w[id name email is_admin]
  }
]

response = client.archive_board(board_id, select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for boards [here](https://developer.monday.com/api-reference/docs/board-view-queries#fields).
