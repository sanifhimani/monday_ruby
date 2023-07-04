# #delete\_column

The `delete_column` mutation will allow you to delete a column from a specific board.

### Basic usage

This method accepts two required arguments - `board_id` and `column_id`.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

board_id = 123
column_id = "keywords"
response = client.delete_column(board_id, column_id)

puts response.body
```
{% endcode %}

This will delete the `keywords` column from the board ID `123`.

This will return the deleted column's ID by default.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "delete_column": {
      "id": "keywords"
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

board_id = 123
column_id = "keywords"
select = %w[id type title]

response =  client.delete_column(board_id, column_id, select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for columns [here](https://developer.monday.com/api-reference/docs/columns#fields).
