# #board\_views

Querying `board_views` will return a collection of board views from a specific board.

### Basic usage

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

response = client.board_views

puts response.body
```
{% endcode %}

This will return the board views' ID, name and type fields by default.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "boards": [
      {
        "views" : [
          {
            "type": "FormBoardView",
            "name": "Contact Form",
            "id": "55567306"
          },
          {
            "type": "ItemsGalleryBoardView",
            "name": "Cards",
            "id": "212647324"
          },
          {
            "type": "KanbanBoardView",
            "name": "Kanban",
            "id": "212644479"
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

This method accepts various arguments to filter down the views. You can find the complete list of arguments [here](https://developer.monday.com/api-reference/docs/board-view-queries#arguments).

You can pass these filters using the `args` option.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

args = {
  ids: [123, 456]
}
response = client.board_views(args: args)

puts response.body
```
{% endcode %}

This will filter and return the views for boards `123` and `456`.

### Customizing fields to retrieve

You can customize the fields to retrieve by passing in the `select` option and listing all the fields you need to retrieve as an array.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

select = %w[id name settings_str type]
response = client.board_views(select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for board views [here](https://developer.monday.com/api-reference/docs/board-view-queries#fields).
