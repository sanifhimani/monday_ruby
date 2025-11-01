# Account

Access your monday.com account information via the `client.account` resource.

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>What is an Account?</span>
Your monday.com account represents your organization's account with billing, subscription, and account-level settings.
:::

## Methods

### query

Retrieves your monday.com account information.

```ruby
client.account.query(select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `select` | Array | `["id", "name"]` | Fields to retrieve |

**Returns:** `Monday::Response`

**Response Structure:**

The account is nested under users:

```ruby
users = response.body.dig("data", "users")
account = users.first&.dig("account")
```

**Available Fields:**

- `id` - Account ID
- `name` - Account name
- `slug` - Account URL slug
- `plan` - Subscription plan information
- `tier` - Account tier
- `country_code` - Account country code
- `first_day_of_the_week` - Week start day preference

**Example:**

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.account.query(
  select: ["id", "name", "slug", "country_code"]
)

if response.success?
  users = response.body.dig("data", "users")
  account = users.first&.dig("account")

  puts "Account: #{account['name']}"
  puts "  ID: #{account['id']}"
  puts "  Slug: #{account['slug']}"
  puts "  Country: #{account['country_code']}"
end
```

**Output:**
```
Account: test-account
  ID: 17545454
  Slug: test-account-slug
  Country: US
```

**GraphQL:** `query { users { account { ... } } }`

**See:** [monday.com account query](https://developer.monday.com/api-reference/reference/account)

## Response Structure

All methods return a `Monday::Response` object. Access data using:

```ruby
response.success?  # => true/false
response.status    # => 200
response.body      # => Hash with GraphQL response
```

### Typical Response Pattern

```ruby
response = client.account.query(
  select: ["id", "name", "plan"]
)

if response.success?
  users = response.body.dig("data", "users")
  account = users.first&.dig("account")

  puts "Account: #{account['name']}"
  puts "Plan: #{account['plan']['tier']}"
else
  # Handle error
end
```

## Constants

### DEFAULT_SELECT

Default fields returned by the account query:

```ruby
["id", "name"]
```

## Error Handling

Common errors when working with accounts:

- `Monday::AuthorizationError` - Invalid or missing API token
- `Monday::Error` - Invalid field requested

**Example:**

```ruby
begin
  response = client.account.query(
    select: ["id", "name", "invalid_field"]
  )
rescue Monday::Error => e
  puts "Error: #{e.message}"
end
```

See the [Error Handling guide](/guides/advanced/errors) for more details.

## Use Cases

### Check Account Information

```ruby
response = client.account.query(
  select: ["id", "name", "slug"]
)

if response.success?
  users = response.body.dig("data", "users")
  account = users.first&.dig("account")

  puts "Connected to: #{account['name']}"
end
```

### Verify Account Tier

```ruby
response = client.account.query(
  select: ["id", "name", "tier"]
)

if response.success?
  users = response.body.dig("data", "users")
  account = users.first&.dig("account")

  if account["tier"] == "enterprise"
    puts "Enterprise account detected"
  end
end
```

### Get Account Settings

```ruby
response = client.account.query(
  select: [
    "id",
    "name",
    "country_code",
    "first_day_of_the_week"
  ]
)

if response.success?
  users = response.body.dig("data", "users")
  account = users.first&.dig("account")

  puts "Settings:"
  puts "  Country: #{account['country_code']}"
  puts "  Week starts: #{account['first_day_of_the_week']}"
end
```

## Related Resources

- [Workspace](/reference/resources/workspace) - Workspaces within your account
- [Board](/reference/resources/board) - Boards in your account
- [Client](/reference/client) - Client authentication

## External References

- [monday.com Account API](https://developer.monday.com/api-reference/reference/account)
- [GraphQL API Overview](https://developer.monday.com/api-reference/docs/introduction-to-graphql)
