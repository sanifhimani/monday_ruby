# #change\_column\_title

The `change_column_title` mutation will allow you to update a column's title.

### Basic usage

This method accepts various arguments to update a column's title. You can find the complete list of arguments [here](https://developer.monday.com/api-reference/docs/columns#arguments-6).

You can pass these filters using the `args` option.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  board_id: 123,
  column_id: "status",
  title: "New Work Status"
}
response = client.change_column_title(args: args)

puts response.body
```
{% endcode %}

This will update the column title for the `status` column on `123` board to "New Work Status".

This will return the columns' ID, title and description fields by default.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "change_column_title": {
      "id": "status",
      "title": "New Work Status",
      "description": "Status Column"
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
  column_id: "status",
  title: "New Work Status"
}
select = %w[id archived width settings_str]

response =  client.change_column_title(args: args, select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for columns [here](https://developer.monday.com/api-reference/docs/columns#fields).
