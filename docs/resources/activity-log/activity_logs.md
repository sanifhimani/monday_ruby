# #activity\_logs

Querying `activity_logs` will return a collection of activity logs from a specific board.

### Basic usage

This method accepts one required argument - `board_ids`, an array of board IDs.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

board_ids = [123, 456]
response = client.activity_logs(board_ids)

puts response.body
```
{% endcode %}

By default, this will return the activity logs' ID, event and data fields.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "boards": [
      {
        "activity_logs": [
          {
            "id": "123-abc",
            "event": "create_column",
            "data": "{\"board_id\":123,\"column_id\":\"date0\",\"column_title\":\"Date\",\"column_type\":\"date\"}"
          },
          {
            "id": "456-def",
            "event": "create_column",
            "data": "{\"board_id\":123,\"column_id\":\"status\",\"column_title\":\"Status\",\"column_type\":\"color\"}"
          },
          {
            "id": "789-ghi",
            "event": "create_column",
            "data": "{\"board_id\":123,\"column_id\":\"name\",\"column_title\":\"Name\",\"column_type\":\"name\"}"
          }
        ]
      }
    ]
  },
 "account_id": 123
}
```
{% endcode %}

### Filtering activity logs

This method accepts various arguments to filter down the activity logs. You can find the complete list of arguments [here](https://developer.monday.com/api-reference/docs/activity-logs#arguments).

You can pass these filters using the `args` option.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

board_ids = [123, 456]
args = {
  from: "2023-01-01T00:00:00Z",
  to: "2023-06-01T00:00:00Z"
}
response = client.activity_logs(board_ids, args: args)

puts response.body
```
{% endcode %}

This will filter and return the logs from Jan 1, 2023, to Jun 1, 2023.

### Customizing fields to retrieve

You can customize the fields to retrieve by passing in the `select` option and listing all the fields you need to retrieve as an array.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

board_ids = [123, 456]

select = %w[id event data entity user_id]
response = client.activity_logs(board_ids, select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for activity logs [here](https://developer.monday.com/api-reference/docs/activity-logs#fields).

{% hint style="info" %}
Visit monday.com's API documentation to know more about the [activity logs API](https://developer.monday.com/api-reference/docs/activity-logs).
{% endhint %}
