# #column\_values

Querying `column_values` will return the metadata for one or a collection of columns.

### Basic usage

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

response = client.column_values

puts response.body
```
{% endcode %}

By default, this will return the columns metadata for the ID, title, and description fields.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
  "data": {
    "boards": [
      {
        "items": [
          {
            "column_values": [
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
          }
        ]
      },
      {
        "items": [
          {
            "column_values": [
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
          },
          {
            "column_values": [
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
      }
    ]
  },
  "account_id": 123
}
```
{% endcode %}

### Customizing fields to retrieve

You can customize the fields to retrieve by passing in the `board_ids` and `item_ids` options and listing all the fields you need to retrieve as an array.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

board_ids = [456]
item_ids = [1234, 5678]
select = %w[id description value]

response = client.column_values(board_ids, item_ids, select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for columns [here](https://developer.monday.com/api-reference/docs/column-values#fields).
