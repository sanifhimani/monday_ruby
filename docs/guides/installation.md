# Installation & Setup

Install the `monday_ruby` gem and configure your development environment.

## Requirements

- Ruby 2.7 or higher
- A monday.com account
- A monday.com API token

Check your Ruby version:

```bash
ruby -v
```

## Install the Gem

### Using Bundler (Recommended)

Add to your `Gemfile`:

```ruby
gem 'monday_ruby'
```

Install:

```bash
bundle install
```

### Using RubyGems

Install directly:

```bash
gem install monday_ruby
```

Verify installation:

```bash
gem list monday_ruby
```

You should see `monday_ruby` with the version number.

## Get Your API Token

1. Log in to your monday.com account
2. Click your profile picture in the top-right corner
3. Select **Administration**
4. Go to the **Connections** section
5. Select **Personal API token** in the sidebar
6. Copy your token

## Configure the Client

### Option 1: Environment Variables (Recommended)

Create a `.env` file in your project root:

```bash
MONDAY_TOKEN=your_token_here
```

Load it in your application:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end
```

Install the dotenv gem:

```bash
gem install dotenv
```

Or add to your `Gemfile`:

```ruby
gem 'dotenv'
```

### Option 2: Direct Configuration

Configure globally:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = "your_token_here"
end
```

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>Security</span>
Never commit API tokens to version control. Always use environment variables or secure credential storage.
:::

### Option 3: Per-Client Configuration

Pass token when creating the client:

```ruby
client = Monday::Client.new(token: "your_token_here")
```

## Verify Setup

Test your configuration:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new
response = client.boards

if response.success?
  puts "Connected successfully!"
  puts "Found #{response.body.dig('data', 'boards').length} boards"
else
  puts "Connection failed: #{response.code}"
end
```

Run this script. If you see "Connected successfully!", you're ready to go.

## Configuration Options

### API Version

Specify the monday.com API version:

```ruby
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
  config.version = "2024-10"
end
```

Default version: `2024-01`

### API Host

Override the API endpoint (rarely needed):

```ruby
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
  config.host = "https://api.monday.com/v2"
end
```

## Next Steps

- [Authenticate and make your first request →](/guides/first-request)
- [Learn about configuration options →](/reference/configuration)
- [Explore error handling →](/guides/advanced/errors)
