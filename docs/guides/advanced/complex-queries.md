# Complex Queries

Build advanced GraphQL queries to retrieve nested data, combine multiple resources, and optimize performance.

## Understanding Field Selection

The `select` parameter controls which fields are returned in the response. It supports both arrays and hashes for nested data.

### Array Syntax for Simple Fields

```ruby
select: ["id", "name", "created_at"]
```

This retrieves only the specified fields from the resource.

### Hash Syntax for Nested Fields

```ruby
select: [
  "id",
  "name",
  {
    board: ["id", "name"]
  }
]
```

This retrieves the item's `id` and `name`, plus nested board information.

### How It Works

The `Util.format_select` method converts Ruby hashes into GraphQL field selection syntax:

- `["id", "name"]` becomes `id name`
- `{ board: ["id", "name"] }` becomes `board { id name }`
- `{ column_values: ["id", "text", "type"] }` becomes `column_values { id text type }`

## Nested Field Selection

Query items with deeply nested data structures.

### Query Items with Column Values

Retrieve items and their column data:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.item.query(
  args: { ids: [987654321] },
  select: [
    "id",
    "name",
    "created_at",
    {
      column_values: ["id", "text", "type", "value"]
    }
  ]
)

if response.success?
  item = response.body.dig("data", "items", 0)

  puts "Item: #{item['name']}"
  puts "\nColumn Values:"

  item["column_values"].each do |col|
    puts "  #{col['id']}: #{col['text']} (#{col['type']})"
  end
end
```

**Example output:**
```
Item: Q4 Marketing Campaign
Column Values:
  status: Done (color)
  person: John Doe (people)
  date4: 2024-12-31 (date)
  text: High Priority (text)
```

### Query Boards with Groups and Items

Retrieve complete board structure:

```ruby
response = client.board.query(
  args: { ids: [1234567890] },
  select: [
    "id",
    "name",
    "description",
    {
      groups: [
        "id",
        "title",
        "color",
        {
          items_page: {
            items: ["id", "name", "state"]
          }
        }
      ]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "boards", 0)

  puts "Board: #{board['name']}"
  puts "Description: #{board['description']}"
  puts "\nGroups:"

  board["groups"].each do |group|
    puts "\n  #{group['title']} (#{group['color']})"

    items = group.dig("items_page", "items") || []
    puts "  Items: #{items.length}"

    items.first(3).each do |item|
      puts "    - #{item['name']} [#{item['state']}]"
    end
  end
end
```

**Example output:**
```
Board: Marketing Projects
Description: Track all marketing initiatives

Groups:

  Q1 Planning (blue)
  Items: 5
    - Website Redesign [active]
    - Email Campaign [active]
    - Social Media Strategy [done]

  Q2 Execution (green)
  Items: 8
    - Content Calendar [active]
    - SEO Optimization [active]
```

### Deep Nesting - Items with Subitems and Column Values

Retrieve items with their subitems and all column data:

```ruby
response = client.item.query(
  args: { ids: [987654321] },
  select: [
    "id",
    "name",
    "state",
    {
      board: ["id", "name"],
      group: ["id", "title"],
      column_values: ["id", "text", "type"],
      subitems: [
        "id",
        "name",
        "state",
        {
          column_values: ["id", "text"]
        }
      ]
    }
  ]
)

if response.success?
  item = response.body.dig("data", "items", 0)
  board = item.dig("board")
  group = item.dig("group")

  puts "Item: #{item['name']}"
  puts "Board: #{board['name']}"
  puts "Group: #{group['title']}"
  puts "State: #{item['state']}"

  puts "\nColumn Values:"
  item["column_values"].each do |col|
    next if col["text"].nil? || col["text"].empty?
    puts "  #{col['id']}: #{col['text']}"
  end

  puts "\nSubitems:"
  item["subitems"].each do |subitem|
    puts "  - #{subitem['name']} [#{subitem['state']}]"

    subitem["column_values"].each do |col|
      next if col["text"].nil? || col["text"].empty?
      puts "      #{col['id']}: #{col['text']}"
    end
  end
end
```

## Query Multiple Resources

Combine different resource queries into a single request by making parallel calls or using custom GraphQL queries.

### Query Boards and Workspaces Together

Get workspace and board information in one flow:

```ruby
# First, get workspaces
workspace_response = client.workspace.query(
  select: [
    "id",
    "name",
    "description"
  ]
)

workspaces = workspace_response.body.dig("data", "workspaces")

# Then, get boards for each workspace
workspaces.each do |workspace|
  board_response = client.board.query(
    args: { workspace_ids: [workspace["id"]] },
    select: [
      "id",
      "name",
      {
        groups: ["id", "title"]
      }
    ]
  )

  boards = board_response.body.dig("data", "boards")

  puts "\nWorkspace: #{workspace['name']}"
  puts "Boards: #{boards.length}"

  boards.each do |board|
    puts "  - #{board['name']} (#{board['groups'].length} groups)"
  end
end
```

### Query Items from Multiple Boards

Retrieve items from different boards with specific fields:

```ruby
board_ids = [1234567890, 2345678901, 3456789012]

board_ids.each do |board_id|
  response = client.board.items_page(
    board_ids: board_id,
    limit: 50,
    select: [
      "id",
      "name",
      {
        board: ["id", "name"],
        column_values: ["id", "text"]
      }
    ]
  )

  if response.success?
    board = response.body.dig("data", "boards", 0)
    items = board.dig("items_page", "items")

    puts "\nBoard: #{board_id}"
    puts "Items: #{items.length}"

    items.first(5).each do |item|
      puts "  - #{item['name']}"
    end
  end
end
```

### Combine Board, Group, and Item Queries

Get complete hierarchical data:

```ruby
# Get board with groups
board_response = client.board.query(
  args: { ids: [1234567890] },
  select: [
    "id",
    "name",
    {
      workspace: ["id", "name"],
      groups: ["id", "title", "color"],
      columns: ["id", "title", "type"]
    }
  ]
)

board = board_response.body.dig("data", "boards", 0)
workspace = board.dig("workspace")

puts "Workspace: #{workspace['name']}"
puts "Board: #{board['name']}"
puts "\nColumns: #{board['columns'].length}"
board['columns'].each do |col|
  puts "  - #{col['title']} (#{col['type']})"
end

puts "\nGroups:"
board["groups"].each do |group|
  # Get items for each group
  items_response = client.group.items_page(
    board_ids: board["id"],
    group_ids: group["id"],
    limit: 100,
    select: [
      "id",
      "name",
      "state",
      {
        column_values: ["id", "text"]
      }
    ]
  )

  if items_response.success?
    group_data = items_response.body.dig("data", "boards", 0, "groups", 0)
    items = group_data.dig("items_page", "items") || []

    puts "\n  #{group['title']} (#{group['color']})"
    puts "  Items: #{items.length}"

    items.first(3).each do |item|
      puts "    - #{item['name']} [#{item['state']}]"
    end
  end
end
```

## Advanced Filtering with query_params

Use complex filtering rules to find specific items.

### Single Rule Filter

Filter items by a single column value:

```ruby
response = client.board.items_page(
  board_ids: 1234567890,
  limit: 100,
  query_params: {
    rules: [
      { column_id: "status", compare_value: [1] }
    ],
    operator: :and
  },
  select: [
    "id",
    "name",
    {
      column_values: ["id", "text"]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "boards", 0)
  items = board.dig("items_page", "items")

  puts "Items with status index 1: #{items.length}"
end
```

::: tip Column Value Indices
Status column values use numeric indices (0, 1, 2, etc.) corresponding to their position in the status settings. Query your board's columns to see the available indices.
:::

### Multiple Rules with AND Logic

All rules must match:

```ruby
response = client.board.items_page(
  board_ids: 1234567890,
  limit: 100,
  query_params: {
    rules: [
      { column_id: "status", compare_value: [1] },
      { column_id: "priority", compare_value: [2] }
    ],
    operator: :and
  }
)

if response.success?
  board = response.body.dig("data", "boards", 0)
  items = board.dig("items_page", "items")

  puts "High priority items with status=1: #{items.length}"
end
```

### Multiple Rules with OR Logic

Any rule can match:

```ruby
response = client.board.items_page(
  board_ids: 1234567890,
  limit: 100,
  query_params: {
    rules: [
      { column_id: "status", compare_value: [1] },
      { column_id: "status", compare_value: [2] }
    ],
    operator: :or
  },
  select: ["id", "name"]
)

if response.success?
  board = response.body.dig("data", "boards", 0)
  items = board.dig("items_page", "items")

  puts "Items with status 1 or 2: #{items.length}"
end
```

### Filter by Date Range

Filter items by date column:

```ruby
# Get items due in the next 7 days
today = Date.today
next_week = today + 7

response = client.board.items_page(
  board_ids: 1234567890,
  limit: 100,
  query_params: {
    rules: [
      {
        column_id: "date4",  # Replace with your date column ID
        compare_value: [today.to_s, next_week.to_s]
      }
    ],
    operator: :and
  },
  select: [
    "id",
    "name",
    {
      column_values: ["id", "text"]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "boards", 0)
  items = board.dig("items_page", "items")

  puts "Items due in next 7 days: #{items.length}"

  items.each do |item|
    date_col = item["column_values"].find { |cv| cv["id"] == "date4" }
    puts "  - #{item['name']}: #{date_col&.dig('text')}"
  end
end
```

### Combine Filtering and Pagination

Filter items and paginate through results:

```ruby
def fetch_filtered_items(client, board_id, query_params)
  all_items = []
  cursor = nil

  loop do
    response = client.board.items_page(
      board_ids: board_id,
      limit: 100,
      cursor: cursor,
      query_params: cursor.nil? ? query_params : nil,  # Only pass on first request
      select: [
        "id",
        "name",
        {
          column_values: ["id", "text"]
        }
      ]
    )

    break unless response.success?

    board = response.body.dig("data", "boards", 0)
    items_page = board.dig("items_page")
    items = items_page["items"]

    break if items.empty?

    all_items.concat(items)
    cursor = items_page["cursor"]

    break if cursor.nil?

    puts "Fetched #{items.length} items, total: #{all_items.length}"
  end

  all_items
end

# Usage: Get all high-priority items
items = fetch_filtered_items(
  client,
  1234567890,
  {
    rules: [{ column_id: "priority", compare_value: [2] }],
    operator: :and
  }
)

puts "\nTotal high-priority items: #{items.length}"
```

## Optimize Query Performance

Reduce complexity and improve response times.

### Select Only Needed Fields

**Bad - Over-fetching:**
```ruby
# Retrieves all default fields plus unnecessary nested data
response = client.item.query(
  args: { ids: [987654321] },
  select: [
    "id",
    "name",
    "created_at",
    "updated_at",
    "creator_id",
    "state",
    "url",
    {
      board: ["id", "name", "description", "state", "url"],
      group: ["id", "title", "color", "position"],
      column_values: ["id", "text", "type", "value"],
      updates: ["id", "body", "created_at", "creator"],
      subitems: ["id", "name", "state", "created_at"]
    }
  ]
)
```

**Good - Minimal fields:**
```ruby
# Only retrieve what you need
response = client.item.query(
  args: { ids: [987654321] },
  select: [
    "id",
    "name",
    {
      column_values: ["id", "text"]
    }
  ]
)
```

### Use Pagination Instead of Large Queries

**Bad - Fetching all items at once:**
```ruby
# This can timeout or hit complexity limits
response = client.item.query(
  args: { limit: 10000 }
)
```

**Good - Paginated approach:**
```ruby
response = client.board.items_page(
  board_ids: 1234567890,
  limit: 100  # Reasonable page size
)

items = response.body.dig("data", "boards", 0, "items_page", "items")
cursor = response.body.dig("data", "boards", 0, "items_page", "cursor")

# Fetch next page if needed
if cursor
  next_response = client.board.items_page(
    board_ids: 1234567890,
    cursor: cursor
  )
end
```

### Avoid Nested Loops of Queries

**Bad - N+1 query problem:**
```ruby
# Gets boards, then queries each board's items separately
boards_response = client.board.query
boards = boards_response.body.dig("data", "boards")

boards.each do |board|
  # This creates N additional queries!
  items_response = client.board.items_page(board_ids: board["id"])
  items = items_response.body.dig("data", "boards", 0, "items_page", "items")
  puts "#{board['name']}: #{items.length} items"
end
```

**Good - Batch query with nested selection:**
```ruby
# Get items in the initial query (for small datasets)
response = client.board.query(
  args: { ids: [1234567890, 2345678901] },
  select: [
    "id",
    "name",
    {
      items_page: {
        items: ["id", "name"]
      }
    }
  ]
)

boards = response.body.dig("data", "boards")
boards.each do |board|
  items = board.dig("items_page", "items") || []
  puts "#{board['name']}: #{items.length} items"
end
```

### Limit Column Value Queries

**Bad - Getting all column data:**
```ruby
response = client.item.query(
  args: { ids: [987654321] },
  select: [
    "id",
    "name",
    {
      column_values: ["id", "text", "type", "value", "additional_info"]
    }
  ]
)
```

**Good - Only needed column fields:**
```ruby
response = client.item.query(
  args: { ids: [987654321] },
  select: [
    "id",
    "name",
    {
      column_values: ["id", "text"]  # Just what you need
    }
  ]
)
```

## Working with Related Data

Navigate relationships between boards, groups, items, and other resources.

### Board → Groups → Items → Column Values

Complete hierarchy traversal:

```ruby
# Get board with groups
board_response = client.board.query(
  args: { ids: [1234567890] },
  select: [
    "id",
    "name",
    {
      groups: ["id", "title"]
    }
  ]
)

board = board_response.body.dig("data", "boards", 0)

puts "Board: #{board['name']}\n\n"

# For each group, get items with column values
board["groups"].each do |group|
  items_response = client.group.items_page(
    board_ids: board["id"],
    group_ids: group["id"],
    limit: 50,
    select: [
      "id",
      "name",
      {
        column_values: ["id", "text", "type"]
      }
    ]
  )

  if items_response.success?
    group_data = items_response.body.dig("data", "boards", 0, "groups", 0)
    items = group_data.dig("items_page", "items") || []

    puts "Group: #{group['title']}"
    puts "Items: #{items.length}\n"

    items.first(3).each do |item|
      puts "  Item: #{item['name']}"

      item["column_values"].each do |col|
        next if col["text"].nil? || col["text"].empty?
        puts "    - #{col['id']}: #{col['text']} (#{col['type']})"
      end
      puts ""
    end
  end
end
```

### Workspace → Folders → Boards

Navigate organizational structure:

```ruby
# Get workspaces
workspace_response = client.workspace.query(
  select: [
    "id",
    "name",
    "description"
  ]
)

workspaces = workspace_response.body.dig("data", "workspaces")

workspaces.each do |workspace|
  puts "\nWorkspace: #{workspace['name']}"

  # Get boards in this workspace
  boards_response = client.board.query(
    args: { workspace_ids: [workspace["id"]] },
    select: [
      "id",
      "name",
      "description",
      {
        groups: ["id", "title"]
      }
    ]
  )

  boards = boards_response.body.dig("data", "boards") || []

  puts "Boards: #{boards.length}\n"

  boards.each do |board|
    puts "  - #{board['name']}"
    puts "    Groups: #{board['groups'].length}"
  end
end
```

### Item → Subitems → Updates

Get item with all related data:

```ruby
response = client.item.query(
  args: { ids: [987654321] },
  select: [
    "id",
    "name",
    "created_at",
    {
      board: ["id", "name"],
      group: ["id", "title"],
      creator: ["id", "name", "email"],
      subitems: [
        "id",
        "name",
        "state",
        {
          column_values: ["id", "text"]
        }
      ],
      updates: [
        "id",
        "body",
        "created_at",
        {
          creator: ["name"]
        }
      ]
    }
  ]
)

if response.success?
  item = response.body.dig("data", "items", 0)

  puts "Item: #{item['name']}"
  puts "Board: #{item.dig('board', 'name')}"
  puts "Group: #{item.dig('group', 'title')}"
  puts "Creator: #{item.dig('creator', 'name')}"
  puts "Created: #{item['created_at']}\n"

  puts "\nSubitems (#{item['subitems'].length}):"
  item["subitems"].each do |subitem|
    puts "  - #{subitem['name']} [#{subitem['state']}]"
  end

  puts "\nUpdates (#{item['updates'].length}):"
  item["updates"].first(5).each do |update|
    creator = update.dig("creator", "name")
    puts "  [#{update['created_at']}] #{creator}:"
    puts "  #{update['body']}\n\n"
  end
end
```

## Custom Select Patterns

Advanced field selection techniques.

### Mixing Arrays and Hashes

Combine simple and nested fields:

```ruby
select: [
  # Simple fields
  "id",
  "name",
  "created_at",
  "state",

  # Nested fields with hash syntax
  {
    board: ["id", "name", "url"],
    group: ["id", "title"],
    creator: ["name", "email"]
  },

  # More simple fields
  "url"
]
```

### Deeply Nested Structures

Multiple levels of nesting:

```ruby
response = client.board.query(
  args: { ids: [1234567890] },
  select: [
    "id",
    "name",
    {
      workspace: [
        "id",
        "name"
      ],
      groups: [
        "id",
        "title",
        "color",
        {
          items_page: {
            items: [
              "id",
              "name",
              {
                column_values: ["id", "text"],
                subitems: [
                  "id",
                  "name",
                  {
                    column_values: ["id", "text"]
                  }
                ]
              }
            ]
          }
        }
      ]
    }
  ]
)
```

### Conditional Field Selection

Select fields based on resource type:

```ruby
def query_with_details(client, item_ids, include_updates: false)
  fields = [
    "id",
    "name",
    {
      board: ["id", "name"],
      column_values: ["id", "text"]
    }
  ]

  # Conditionally add updates
  if include_updates
    fields << {
      updates: ["id", "body", "created_at"]
    }
  end

  client.item.query(
    args: { ids: item_ids },
    select: fields
  )
end

# Usage
response = query_with_details(client, [987654321], include_updates: true)
```

### Reusable Field Definitions

Create reusable field sets:

```ruby
# Define common field sets
BASIC_ITEM_FIELDS = ["id", "name", "created_at"].freeze

ITEM_WITH_BOARD = [
  *BASIC_ITEM_FIELDS,
  {
    board: ["id", "name"]
  }
].freeze

ITEM_WITH_COLUMNS = [
  *BASIC_ITEM_FIELDS,
  {
    column_values: ["id", "text", "type"]
  }
].freeze

FULL_ITEM_FIELDS = [
  *BASIC_ITEM_FIELDS,
  "state",
  "url",
  {
    board: ["id", "name"],
    group: ["id", "title"],
    column_values: ["id", "text", "type"],
    creator: ["name", "email"]
  }
].freeze

# Use them in queries
response = client.item.query(
  args: { ids: [987654321] },
  select: FULL_ITEM_FIELDS
)
```

## Complete Example

Comprehensive complex query combining multiple techniques:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# Get board with complete structure
board_response = client.board.query(
  args: {
    ids: [1234567890],
    state: :active
  },
  select: [
    "id",
    "name",
    "description",
    {
      workspace: ["id", "name"],
      columns: ["id", "title", "type"],
      groups: ["id", "title", "color"]
    }
  ]
)

unless board_response.success?
  puts "Failed to fetch board"
  exit 1
end

board = board_response.body.dig("data", "boards", 0)

puts "\n" + "=" * 70
puts "BOARD: #{board['name']}"
puts "=" * 70
puts "Workspace: #{board.dig('workspace', 'name')}"
puts "Description: #{board['description']}"
puts "\nColumns (#{board['columns'].length}):"
board['columns'].each do |col|
  puts "  - #{col['title']} (#{col['type']})"
end

puts "\n" + "-" * 70

# For each group, get filtered items
board['groups'].each do |group|
  puts "\nGROUP: #{group['title']} (#{group['color']})"

  # Get items with filters
  items_response = client.group.items_page(
    board_ids: board["id"],
    group_ids: group["id"],
    limit: 100,
    query_params: {
      rules: [
        { column_id: "status", compare_value: [1] }
      ],
      operator: :and
    },
    select: [
      "id",
      "name",
      "state",
      "created_at",
      {
        column_values: ["id", "text", "type"],
        creator: ["name", "email"],
        subitems: ["id", "name", "state"]
      }
    ]
  )

  next unless items_response.success?

  group_data = items_response.body.dig("data", "boards", 0, "groups", 0)
  items = group_data.dig("items_page", "items") || []
  cursor = group_data.dig("items_page", "cursor")

  puts "Items with status=1: #{items.length}"

  items.first(5).each do |item|
    creator = item.dig("creator")
    subitems_count = item["subitems"].length

    puts "\n  Item: #{item['name']}"
    puts "    State: #{item['state']}"
    puts "    Created: #{item['created_at']}"
    puts "    Creator: #{creator&.dig('name')} (#{creator&.dig('email')})"
    puts "    Subitems: #{subitems_count}"

    # Show column values
    puts "    Columns:"
    item["column_values"].each do |col|
      next if col["text"].nil? || col["text"].empty?
      puts "      #{col['id']}: #{col['text']}"
    end
  end

  if cursor
    puts "\n  [More items available - use cursor for pagination]"
  end
end

puts "\n" + "=" * 70
```

## Performance Tips

1. **Request only what you need**: Minimize fields in `select` to reduce response size
2. **Use pagination**: Always use `items_page` for large datasets instead of `items`
3. **Batch queries**: Combine related data in single queries when possible
4. **Cache results**: Store frequently accessed data to reduce API calls
5. **Filter server-side**: Use `query_params` instead of fetching all items and filtering in Ruby
6. **Monitor complexity**: monday.com has complexity limits - simpler queries are faster
7. **Use cursors**: Cursor-based pagination is more efficient than offset-based

## Next Steps

- [Pagination guide](/guides/advanced/pagination)
- [Error handling](/guides/advanced/errors)
- [Rate limiting strategies](/guides/advanced/rate-limiting)
- [Batch operations](/guides/advanced/batch)
