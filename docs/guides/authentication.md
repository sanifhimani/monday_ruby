# Authentication

Manage API tokens and authenticate your monday.com requests securely.

## Overview

monday_ruby uses API tokens for authentication. Every request to the monday.com API requires a valid token.

## Token Types

### Personal API Token

For individual use and testing:

1. Log in to monday.com
2. Click your profile picture → **Administration**
3. Go to **Connections** → **Personal API token**
4. Copy your token

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Token Permissions</span>
Personal API tokens have the same permissions as your monday.com account. Use carefully in production.
:::

### App-Based Tokens

For production integrations, create a monday.com app:

1. Go to the monday.com Developers Center
2. Create a new app
3. Generate OAuth tokens for users

See [monday.com's OAuth documentation](https://developer.monday.com/apps/docs/oauth) for details.

## Secure Token Storage

### Development: Environment Variables

Use a `.env` file:

```bash
# .env
MONDAY_TOKEN=your_token_here
```

Add to `.gitignore`:

```bash
# .gitignore
.env
```

Load in your application:

```ruby
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end
```

### Production: Credential Management

Use secure credential storage:

**Rails Credentials:**

```bash
rails credentials:edit
```

Add:

```yaml
monday:
  token: your_token_here
```

Load:

```ruby
Monday.configure do |config|
  config.token = Rails.application.credentials.monday[:token]
end
```

**Environment Variables:**

Set on your hosting platform:

```bash
# Heroku
heroku config:set MONDAY_TOKEN=your_token_here

# AWS Lambda
# Set in Lambda environment variables

# Docker
docker run -e MONDAY_TOKEN=your_token_here
```

## Configuration Methods

### Global Configuration

Set once, use everywhere:

```ruby
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

# All clients use this token
client = Monday::Client.new
```

### Per-Client Configuration

Use different tokens for different clients:

```ruby
# Client 1 with token A
client_a = Monday::Client.new(token: ENV["MONDAY_TOKEN_A"])

# Client 2 with token B
client_b = Monday::Client.new(token: ENV["MONDAY_TOKEN_B"])
```

### Dynamic Token Switching

Change tokens at runtime:

```ruby
Monday.configure do |config|
  config.token = user.monday_token
end

client = Monday::Client.new
```

## Verify Authentication

Test if your token is valid:

```ruby
client = Monday::Client.new

response = client.account.query(
  select: ["id", "name"]
)

if response.success?
  account = response.body.dig("data", "account")
  puts "Authenticated as: #{account['name']}"
else
  puts "Authentication failed"
end
```

## Handle Authentication Errors

Catch authentication failures:

```ruby
begin
  client = Monday::Client.new(token: "invalid_token")
  response = client.boards

  unless response.success?
    puts "Request failed: #{response.code}"
  end
rescue Monday::AuthorizationError => e
  puts "Invalid API token: #{e.message}"
rescue Monday::Error => e
  puts "API error: #{e.message}"
end
```

## Token Rotation

Rotate tokens regularly for security:

```ruby
# 1. Generate new token in monday.com
# 2. Update environment variable
# 3. Deploy with new token
# 4. Revoke old token after verification

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN_NEW"]
end

# Test new token
client = Monday::Client.new
response = client.boards

if response.success?
  puts "New token works. Safe to revoke old token."
end
```

## Multi-Tenant Applications

Handle multiple monday.com accounts:

```ruby
class MondayService
  def initialize(user)
    @client = Monday::Client.new(token: user.monday_token)
  end

  def fetch_boards
    @client.boards
  end
end

# Usage
service = MondayService.new(current_user)
response = service.fetch_boards
```

## Security Best Practices

### Never Log Tokens

Avoid logging sensitive data:

```ruby
# Bad
logger.info "Token: #{ENV['MONDAY_TOKEN']}"

# Good
logger.info "Authenticating with monday.com"
```

### Use Read-Only Tokens

For read-only operations, create tokens with limited scopes in your monday.com app settings.

### Validate Tokens on Startup

Check authentication before running:

```ruby
def validate_monday_token!
  client = Monday::Client.new
  response = client.account.query(select: ["id"])

  raise "Invalid monday.com token" unless response.success?
end

validate_monday_token!
```

### Rotate Regularly

Change tokens every 90 days or after team member changes.

## Troubleshooting

### "Invalid token" Error

- Verify token is copied correctly (no extra spaces)
- Check token hasn't been revoked
- Ensure token has necessary permissions

### "Unauthorized" Error

- Token may lack permissions for the requested operation
- Verify your monday.com account has access to the board/workspace

### Token Not Loading

```ruby
# Debug environment variable loading
puts "Token loaded: #{ENV['MONDAY_TOKEN'] ? 'Yes' : 'No'}"

# Verify dotenv is loaded
require "dotenv/load"
```

## Next Steps

- [Make your first request →](/guides/first-request)
- [Understand error handling →](/guides/advanced/errors)
- [Learn about configuration →](/reference/configuration)
