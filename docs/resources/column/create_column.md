# #create\_column

The `create_column` mutation will allow you to create a column.

### Basic usage

This method accepts various arguments to create a column. You can find the complete list of arguments [here](https://developer.monday.com/api-reference/docs/columns#arguments-1).

You can pass these filters using the `args` option.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  board_id: 123,
  title: "Work Status",
  description: "This is the work status column",
  column_type: status
}
response = client.create_column(args: args)

puts response.body
```
{% endcode %}

This will create a new column on the `123` board titled "Work Status" and the "This is the work status column" description with the column type as status.

This will return the columns' ID, title and description fields by default.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "create_column": {
      "id": "status",
      "title": "Work Status",
      "description": "This is the work status column"
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
  title: "Work Status",
  description: "This is the work status column",
  column_type: status
}
select = %w[id archived width settings_str]

response =  client.create_column(args: args, select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for columns [here](https://developer.monday.com/api-reference/docs/columns#fields).
