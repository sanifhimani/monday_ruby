# #change\_column\_value

The `change_column_value` mutation will allow you to update the value of a column for a specific item.

### Basic usage

This method accepts various arguments to update the column's value. You can find the complete list of arguments [here](https://developer.monday.com/api-reference/docs/columns#arguments-3).

You can pass these filters using the `args` option.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  board_id: 123,
  item_id: 1234,
  column_id: "status",
  value: {
    label: "Working on it"
  }
}
response = client.change_column_value(args: args)

puts response.body
```
{% endcode %}

This will update the `status` column value for item ID `1234` on the board ID `123` to "Working on it".

This will return the items' ID and name fields by default.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "change_column_value": {
      "id": "1234",
      "name": "Task 1"
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
  board_id: 123,
  item_id: 1234,
  column_id: "status",
  value: {
    label: "Working on it"
  }
}
select = %w[id name email]

response =  client.change_column_value(args: args, select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for items [here](https://developer.monday.com/api-reference/docs/items#fields).
