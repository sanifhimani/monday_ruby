# #delete\_board\_subscribers

The `delete_board_subscribers` mutation will allow you to delete subscribers from a board.

### Basic usage

This method accepts two required parameters - `board_id` and `user_ids`.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

board_id = 789
user_ids = [123, 456]
response = client.delete_board_subscribers(board_id, user_ids)

puts response.body
```
{% endcode %}

This will delete `123` and `456` subscribers from the `789` board.

This will return the deleted subscriber's ID by default.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "delete_subscribers_from_board": [
      {
        "id": 123
      },
      {
        "id": 456
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

board_id = 789
user_ids = [123, 456]
select = %w[id name is_guest is_admin]

response = client.delete_board_subscribers(board_id, user_ids, select: select)

puts response.body
```
{% endcode %}

### Retrieving nested fields

Some fields have nested attributes, and you need to specify the attributes to retrieve that field; else, the API will respond with an error.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

board_id = 789
user_ids = [123, 456]
select = [
  "id",
  "name",
  {
    account: %w[id slug tier]
  }
]

response = client.delete_board_subscribers(board_id, user_ids, select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for boards [here](https://developer.monday.com/api-reference/docs/board-view-queries#fields).
