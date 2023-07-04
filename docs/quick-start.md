# Quick Start

The following is the minimum needed to fetch all the boards with their IDs and column IDs:

{% code lineNumbers="true" %}
```ruby
require "monday_ruby"

client = Monday::Client.new(token: <AUTH_TOKEN>)

select = [
  "id",
  {
    columns: "id"
  }
]

response = client.boards(select: select)
# => <Monday::Response ...>

puts response.body
```
{% endcode %}

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "boards": [
      {
        "id": "123",
        "columns": [
          {
            "id": "name"
          },
          {
            "id": "subitems"
          },
          {
            "id": "work_status"
          },
          {
            "id": "keywords"
          }
        ]
      },
      {
        "id": "456",
        "columns": [
          {
            "id": "name"
          },
          {
            "id": "person"
          },
          {
            "id": "status"
          },
          {
            "id": "date0"
          }
        ]
      },
    ]
  },
  "account_id": 123
}
```
{% endcode %}

### Advanced select query

The following is the minimum needed to fetch:

1. All the boards' IDs, names and count of items on each board.
2. The ID, title and type for the columns on each board.
3. The ID, name and the value of the items on each board.

{% code lineNumbers="true" %}
```ruby
require "monday_ruby"

client = Monday::Client.new(token: <AUTH_TOKEN>)

select = [
  "id",
  "name",
  "items_count",
  {
    columns: %w[id title type],
    items: [
      "id",
      "name",
      {
        column_values: "value"
      }
    ]
  }
]

response = client.boards(select: select)
# => <Monday::Response ...>

puts response.body
```
{% endcode %}

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "boards": [
      {
        "id": "123",
        "name": "New test board",
        "items_count": 2,
        "columns": [
          {
            "id": "name",
            "title": "Name",
            "type": "name"
          },
          {
            "id": "subitems",
            "title": "Subitems",
            "type": "subtasks"
          },
          {
            "id": "work_status",
            "title": "Status",
            "type": "color"
          },
          {
            "id": "keywords",
            "title": "Keywords",
            "type": "dropdown"
          }
        ],
        "items": [
          {
            "id": "4708726090",
            "name": "Task 1",
            "column_values": [
              {
                "value": null
              },
              {
                "value": "{\"index\":0,\"changed_at\":\"2023-06-27T16:21:22.192Z\"}"
              },
              {
                "value": "{\"ids\":[1]}"
              }
            ]
          },
          {
            "id": "4713421325",
            "name": "New item",
            "column_values": [
              {
                "value": null
              },
              {
                "value": null
              },
              {
                "value": null
              }
            ]
          }
        ]
      },
      {
        "id": "456",
        "name": "Your first board",
        "items_count": 3,
        "columns": [
          {
            "id": "name",
            "title": "Name",
            "type": "name"
          },
          {
            "id": "subitems",
            "title": "Subitems",
            "type": "subtasks"
          },
          {
            "id": "person",
            "title": "Person",
            "type": "multiple-person"
          },
          {
            "id": "status",
            "title": "Status",
            "type": "color"
          },
          {
            "id": "date4",
            "title": "Date",
            "type": "date"
          }
        ],
        "items": [
          {
            "id": "4691485763",
            "name": "Item 1",
            "column_values": [
              {
                "value": null
              },
              {
                "value": "{\"changed_at\":\"2022-10-26T12:39:58.664Z\",\"personsAndTeams\":[{\"id\":44865791,\"kind\":\"person\"}]}"
              },
              {
                "value": "{\"index\":0,\"post_id\":null,\"changed_at\":\"2019-03-01T17:24:57.321Z\"}"
              },
              {
                "value": "{\"date\":\"2023-06-21\",\"icon\":null,\"changed_at\":\"2022-12-18T14:03:06.455Z\"}"
              }
            ]
          },
          {
            "id": "4691485774",
            "name": "Item 2",
            "column_values": [
              {
                "value": null
              },
              {
                "value": null
              },
              {
                "value": "{\"index\":1,\"post_id\":null,\"changed_at\":\"2019-03-01T17:28:23.178Z\"}"
              },
              {
                "value": "{\"date\":\"2023-06-23\",\"icon\":null,\"changed_at\":\"2022-12-25T12:31:18.096Z\"}"
              }
            ]
          },
          {
            "id": "4691485784",
            "name": "Item 3",
            "column_values": [
              {
                "value": null
              },
              {
                "value": null
              },
              {
                "value": "{\"index\":2,\"post_id\":null,\"changed_at\":\"2022-12-11T14:33:50.083Z\"}"
              },
              {
                "value": "{\"date\":\"2023-06-25\",\"changed_at\":\"2022-12-25T12:31:20.220Z\"}"
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
