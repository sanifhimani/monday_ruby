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

:::code-group
```bash [Terminal]
gem install monday_ruby
```

```ruby [Gemfile]
gem 'monday_ruby'
```
:::

Then run `bundle install` if using Bundler, or verify with `gem list monday_ruby`.

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

:::warning Security
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

:::details{title="Advanced configuration options"}

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

:::
