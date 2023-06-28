# #columns

Querying `columns` will return the metadata for one or a collection of columns.

### Basic usage

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

response = client.columns

puts response.body
```
{% endcode %}

This will return the columns' ID, title and description fields by default.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "boards": [
      {
        "columns": [
          {
            "id": "name",
            "title": "Name",
            "description": null
          },
          {
            "id": "subitems",
            "title": "Subitems",
            "description": null
          },
          {
            "id": "work_status",
            "title": "Status",
            "description": "New description"
          },
          {
            "id": "keywords",
            "title": "Keywords",
            "description": "This is keywords column"
          }
        ]
      },
      {
        "columns": [
          {
            "id": "name",
            "title": "Name",
            "description": null
          },
          {
            "id": "person",
            "title": "Owner",
            "description": null
          },
          {
            "id": "status",
            "title": "Status",
            "description": null
          },
          {
            "id": "date0",
            "title": "Date",
            "description": null
          }
        ]
      }
    ]
  },
  "account_id": 123
}
```
{% endcode %}

### Filtering board views

This method accepts various arguments to filter down the columns. You can find the complete list of arguments [here](https://developer.monday.com/api-reference/docs/columns#arguments).

You can pass these filters using the `args` option.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  ids: [456],
}
response = client.columns(args: args)

puts response.body
```
{% endcode %}

This will filter and return the columns that belong to board ID `456`.

### Customizing fields to retrieve

You can customize the fields to retrieve by passing in the `select` option and listing all the fields you need to retrieve as an array.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

select = %w[id archived width settings_str]
response = client.columns(select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for columns [here](https://developer.monday.com/api-reference/docs/columns#fields).
