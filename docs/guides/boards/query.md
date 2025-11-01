# Query Boards

Retrieve and filter boards from your monday.com account.

## Basic Query

Get all boards with default fields (ID, name, description):

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.board.query

if response.success?
  boards = response.body.dig("data", "boards")
  puts "Found #{boards.length} boards"
end
```

## Query by IDs

Retrieve specific boards:

```ruby
response = client.board.query(
  args: { ids: [1234567890, 2345678901, 3456789012] }
)

if response.success?
  boards = response.body.dig("data", "boards")

  boards.each do |board|
    puts "#{board['name']} (ID: #{board['id']})"
  end
end
```

## Filter by State

Query boards by their state:

### Active Boards Only (Default)

```ruby
response = client.board.query(
  args: { state: :active }
)
```

### Include Archived Boards

```ruby
response = client.board.query(
  args: { state: :archived }
)

if response.success?
  boards = response.body.dig("data", "boards")
  puts "Found #{boards.length} archived boards"
end
```

### All Boards (Active + Archived)

```ruby
response = client.board.query(
  args: { state: :all }
)
```

### Deleted Boards

```ruby
response = client.board.query(
  args: { state: :deleted }
)
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>State Values</span>
Available states: `:active`, `:archived`, `:deleted`, `:all`
:::

## Filter by Board Type

Query by privacy level:

### Public Boards

```ruby
response = client.board.query(
  args: { board_kind: :public }
)
```

### Private Boards

```ruby
response = client.board.query(
  args: { board_kind: :private }
)
```

### Shareable Boards

```ruby
response = client.board.query(
  args: { board_kind: :share }
)
```

## Filter by Workspace

Get boards from specific workspaces:

```ruby
workspace_ids = [9876543210, 9876543211]

response = client.board.query(
  args: { workspace_ids: workspace_ids }
)

if response.success?
  boards = response.body.dig("data", "boards")
  puts "Found #{boards.length} boards in workspaces #{workspace_ids.join(', ')}"
end
```

## Pagination

Retrieve boards in pages:

### Using Limit and Page

```ruby
# Get first 10 boards
response = client.board.query(
  args: {
    limit: 10,
    page: 1
  }
)

if response.success?
  boards = response.body.dig("data", "boards")
  puts "Page 1: #{boards.length} boards"
end

# Get next 10 boards
response = client.board.query(
  args: {
    limit: 10,
    page: 2
  }
)
```

### Fetch All Boards with Pagination

```ruby
def fetch_all_boards(client)
  all_boards = []
  page = 1
  limit = 25

  loop do
    response = client.board.query(
      args: {
        limit: limit,
        page: page
      }
    )

    break unless response.success?

    boards = response.body.dig("data", "boards")
    break if boards.empty?

    all_boards.concat(boards)
    puts "Fetched page #{page}: #{boards.length} boards"

    page += 1
  end

  all_boards
end

# Usage
boards = fetch_all_boards(client)
puts "\nTotal boards: #{boards.length}"
```

## Sort Results

Order boards by creation or usage:

### Sort by Creation Date (Newest First)

```ruby
response = client.board.query(
  args: { order_by: :created_at }
)

if response.success?
  boards = response.body.dig("data", "boards")

  puts "Most recent boards:"
  boards.first(5).each do |board|
    puts "  • #{board['name']}"
  end
end
```

### Sort by Last Used (Most Recent First)

```ruby
response = client.board.query(
  args: { order_by: :used_at }
)
```

## Combine Filters

Use multiple filters together:

```ruby
response = client.board.query(
  args: {
    workspace_ids: [9876543210],
    board_kind: :public,
    state: :active,
    limit: 50,
    order_by: :used_at
  }
)

if response.success?
  boards = response.body.dig("data", "boards")
  puts "Found #{boards.length} active public boards"
end
```

## Custom Fields Selection

Request specific fields:

### Basic Fields

```ruby
response = client.board.query(
  select: ["id", "name", "description", "state", "url"]
)

if response.success?
  boards = response.body.dig("data", "boards")

  boards.each do |board|
    puts "Name: #{board['name']}"
    puts "State: #{board['state']}"
    puts "URL: #{board['url']}"
    puts "---"
  end
end
```

### With Workspace Information

```ruby
response = client.board.query(
  select: [
    "id",
    "name",
    {
      workspace: ["id", "name"]
    }
  ]
)

if response.success?
  boards = response.body.dig("data", "boards")

  boards.each do |board|
    workspace = board.dig("workspace")
    puts "#{board['name']} → Workspace: #{workspace&.dig('name')}"
  end
end
```

## Query with Columns

Get board structure information:

```ruby
response = client.board.query(
  args: { ids: [1234567890] },
  select: [
    "id",
    "name",
    {
      columns: ["id", "title", "type", "settings_str"]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "boards", 0)

  puts "Board: #{board['name']}"
  puts "\nColumns:"

  board["columns"].each do |column|
    puts "  • #{column['title']} (#{column['type']})"
  end
end
```

**Example output:**
```
Board: Marketing Campaigns
Columns:
  • Name (name)
  • Person (people)
  • Status (color)
  • Priority (color)
  • Due Date (date)
```

## Query with Items

Retrieve boards with their items:

```ruby
response = client.board.query(
  args: { ids: [1234567890] },
  select: [
    "id",
    "name",
    {
      items: [
        "id",
        "name",
        "state"
      ]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "boards", 0)

  puts "Board: #{board['name']}"
  puts "Items: #{board['items'].length}"

  board["items"].first(5).each do |item|
    puts "  • #{item['name']}"
  end
end
```

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Items Deprecation</span>
The `items` field is deprecated. Use [`items_page`](/guides/advanced/pagination) for paginated item retrieval instead.
:::

## Query with Groups

Get board groups (sections):

```ruby
response = client.board.query(
  args: { ids: [1234567890] },
  select: [
    "id",
    "name",
    {
      groups: [
        "id",
        "title",
        "color"
      ]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "boards", 0)

  puts "Board: #{board['name']}"
  puts "Groups:"

  board["groups"].each do |group|
    puts "  • #{group['title']} (#{group['color']})"
  end
end
```

## Query Owners and Subscribers

Get board team information:

```ruby
response = client.board.query(
  args: { ids: [1234567890] },
  select: [
    "id",
    "name",
    {
      owners: ["id", "name", "email"],
      subscribers: ["id", "name"]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "boards", 0)

  puts "Board: #{board['name']}"

  puts "\nOwners:"
  board["owners"].each do |owner|
    puts "  • #{owner['name']} (#{owner['email']})"
  end

  puts "\nSubscribers: #{board['subscribers'].length}"
end
```

## Search by Name

Find boards matching a pattern:

```ruby
def find_boards_by_name(client, search_term)
  response = client.board.query(
    select: ["id", "name", "description"]
  )

  return [] unless response.success?

  boards = response.body.dig("data", "boards")

  boards.select do |board|
    board["name"].downcase.include?(search_term.downcase)
  end
end

# Usage
matching_boards = find_boards_by_name(client, "marketing")

puts "Boards matching 'marketing':"
matching_boards.each do |board|
  puts "  • #{board['name']}"
end
```

## Complete Example

Comprehensive board querying:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# Query with multiple filters and detailed fields
response = client.board.query(
  args: {
    state: :active,
    board_kind: :public,
    limit: 10,
    order_by: :used_at
  },
  select: [
    "id",
    "name",
    "description",
    "state",
    "url",
    {
      workspace: ["id", "name"],
      columns: ["id", "title", "type"],
      owners: ["name", "email"]
    }
  ]
)

if response.success?
  boards = response.body.dig("data", "boards")

  puts "\n📋 Your Boards\n#{'=' * 60}\n"

  boards.each do |board|
    workspace = board.dig("workspace")

    puts "\n#{board['name']}"
    puts "  ID: #{board['id']}"
    puts "  State: #{board['state']}"
    puts "  Workspace: #{workspace&.dig('name') || 'None'}"
    puts "  Columns: #{board['columns'].length}"
    puts "  Owners: #{board['owners'].map { |o| o['name'] }.join(', ')}"
    puts "  URL: #{board['url']}"

    if board['description'] && !board['description'].empty?
      puts "  Description: #{board['description']}"
    end
  end

  puts "\n#{'=' * 60}"
  puts "Total: #{boards.length} boards"
else
  puts "❌ Failed to query boards"
  puts "Status: #{response.status}"
end
```

## Next Steps

- [Create a board](/guides/boards/create)
- [Update board settings](/guides/boards/update)
- [Query items with pagination](/guides/advanced/pagination)
- [Work with columns](/guides/columns/create)
