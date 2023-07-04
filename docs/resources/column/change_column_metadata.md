# #change\_column\_metadata

The `change_column_metadata` mutation will allow you to update the metadata of a column.

### Basic usage

This method accepts various arguments to update a column's metadata. You can find the complete list of arguments [here](https://developer.monday.com/api-reference/docs/columns#arguments-7).

You can pass these filters using the `args` option.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  board_id: 123,
  column_id: "status",
  column_property: "description",
  value: "Updated status column description"
}
response = client.change_column_metadata(args: args)

puts response.body
```
{% endcode %}

This will update the description for the `status` column on `123` board to "Updated status column description".

This will return the columns' ID, title and description fields by default.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "change_column_metadata": {
      "id": "status",
      "title": "New Work Status",
      "description": "Updated status column description"
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
  column_property: "description",
  value: "Updated status column description"
}
select = %w[id archived width settings_str]

response =  client.change_column_metadata(args: args, select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for columns [here](https://developer.monday.com/api-reference/docs/columns#fields).
