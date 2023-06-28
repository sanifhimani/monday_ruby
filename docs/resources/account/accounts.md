# #accounts

Querying the `account` API will return the metadata for the account.

{% hint style="info" %}
This account is the one that is associated with the authentication token.
{% endhint %}

### Basic usage

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

response = client.account
# => <Monday::Response ...>

puts response.body
```
{% endcode %}

By default, this will return the ID and name of the account.

The response body from the above query would be as follows:

{% code lineNumbers="true" %}
```json
{
  "data": {
    "users": [
      {
        "account": {
          "id": 1234,
          "name": "Test User's Team"
        }
      }
    ]
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

select = %w[id name slug logo country_code]

response = client.account(select: select)

puts response.body
```
{% endcode %}

### Retrieving nested fields

Some fields have nested attributes, and you need to specify the attributes to retrieve that field; else, the API will respond with an error. For example, the field `plan` is of type `Plan` and expects you to pass the attributes you want to retrieve for the `plan` field.

{% code lineNumbers="true" %}
```ruby
client = Monday::Client.new(token: <AUTH_TOKEN>)

select = [
  "id",
  "name",
  {
    creator: %w[id name email is_admin]
  }
]

response = client.boards(select: select)

puts response.body
```
{% endcode %}

You can find the list of all the available fields for account [here](https://developer.monday.com/api-reference/docs/account#fields).

{% hint style="info" %}
Visit monday.com's API documentation to know more about the [account API](https://developer.monday.com/api-reference/docs/account).
{% endhint %}
