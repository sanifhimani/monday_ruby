# Board View

Access board views via the `client.board_view` resource.

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>What are Board Views?</span>
Board views are different ways to visualize and interact with your board data, such as main table, kanban, calendar, chart, timeline, and more.
:::

## Methods

### query

Retrieves views for boards.

```ruby
client.board_view.query(args: {}, select: DEFAULT_SELECT)
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Query arguments (see [boards query](https://developer.monday.com/api-reference/reference/boards#queries)) |
| `select` | Array | `["id", "name", "type"]` | Fields to retrieve |

**Returns:** `Monday::Response`

**Common args:**
- `ids` - Array of board IDs
- `limit` - Integer - Maximum number of boards to return
- `page` - Integer - Page number for pagination

**Available Fields:**

- `id` - View ID
- `name` - View name
- `type` - View type (e.g., "BoardView", "KanbanView", "CalendarView", "TimelineView")
- `settings_str` - JSON string with view settings
- `view_specific_data_str` - JSON string with view-specific data

**View Types:**

- `BoardView` - Main table view
- `KanbanView` - Kanban board view
- `CalendarView` - Calendar view
- `TimelineView` - Timeline/Gantt view
- `ChartView` - Chart view
- `MapView` - Map view
- `FormView` - Form view
- `WorkloadView` - Workload view
- `FilesView` - Files gallery view

**Response Structure:**

Views are nested under boards:

```ruby
boards = response.body.dig("data", "boards")
views = boards.first&.dig("views") || []
```

**Example:**

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.board_view.query(
  args: { ids: [1234567890] }
)

if response.success?
  boards = response.body.dig("data", "boards")
  views = boards.first&.dig("views") || []

  puts "Found #{views.length} views"
  views.each do |view|
    puts "  • #{view['name']}: #{view['type']} (ID: #{view['id']})"
  end
end
```

**Output:**
```
Found 4 views
  • Main Table: BoardView (ID: 12345)
  • Kanban: KanbanView (ID: 12346)
  • Calendar: CalendarView (ID: 12347)
  • Timeline: TimelineView (ID: 12348)
```

**GraphQL:** `query { boards { views { ... } } }`

**See:** [monday.com views query](https://developer.monday.com/api-reference/reference/views)

## Query Multiple Boards

Get views from multiple boards:

```ruby
response = client.board_view.query(
  args: { ids: [1234567890, 2345678901] },
  select: ["id", "name", "type"]
)

if response.success?
  boards = response.body.dig("data", "boards")

  boards.each do |board|
    views = board["views"] || []
    puts "Board #{board['id']}: #{views.length} views"

    views.each do |view|
      puts "  • #{view['name']} (#{view['type']})"
    end
  end
end
```

## Get View Settings

Retrieve and parse view settings:

```ruby
require "json"

response = client.board_view.query(
  args: { ids: [1234567890] },
  select: ["id", "name", "type", "settings_str"]
)

if response.success?
  boards = response.body.dig("data", "boards")
  views = boards.first&.dig("views") || []

  views.each do |view|
    puts "\n#{view['name']} (#{view['type']})"

    if view["settings_str"]
      settings = JSON.parse(view["settings_str"])
      puts "  Settings: #{settings.keys.join(', ')}"
    end
  end
end
```

## Filter Views by Type

Find all views of a specific type:

```ruby
def find_views_by_type(client, board_id, view_type)
  response = client.board_view.query(
    args: { ids: [board_id] },
    select: ["id", "name", "type"]
  )

  return [] unless response.success?

  boards = response.body.dig("data", "boards")
  views = boards.first&.dig("views") || []

  views.select { |view| view["type"] == view_type }
end

# Usage
kanban_views = find_views_by_type(client, 1234567890, "KanbanView")

puts "Kanban Views: #{kanban_views.length}"
kanban_views.each do |view|
  puts "  • #{view['name']} (ID: #{view['id']})"
end
```

## List All View Types

Get an overview of all view types on a board:

```ruby
response = client.board_view.query(
  args: { ids: [1234567890] },
  select: ["id", "name", "type"]
)

if response.success?
  boards = response.body.dig("data", "boards")
  views = boards.first&.dig("views") || []

  by_type = views.group_by { |view| view["type"] }

  puts "View Types:"
  by_type.each do |type, views_of_type|
    puts "  #{type}: #{views_of_type.length} view(s)"
  end
end
```

**Output:**
```
View Types:
  BoardView: 1 view(s)
  KanbanView: 2 view(s)
  CalendarView: 1 view(s)
  TimelineView: 1 view(s)
```

## Response Structure

All methods return a `Monday::Response` object. Access data using:

```ruby
response.success?  # => true/false
response.status    # => 200
response.body      # => Hash with GraphQL response
```

### Typical Response Pattern

```ruby
response = client.board_view.query(
  args: { ids: [1234567890] }
)

if response.success?
  boards = response.body.dig("data", "boards")
  views = boards.first&.dig("views") || []

  # Work with views
else
  # Handle error
end
```

## Constants

### DEFAULT_SELECT

Default fields returned by the board view query:

```ruby
["id", "name", "type"]
```

## Error Handling

Common errors when working with board views:

- `Monday::AuthorizationError` - Invalid or missing API token
- `Monday::InvalidRequestError` - Invalid board ID
- `Monday::Error` - Invalid field or other API errors

**Example:**

```ruby
begin
  response = client.board_view.query(
    args: { ids: [123] }  # Invalid ID
  )
rescue Monday::InvalidRequestError => e
  puts "Error: #{e.message}"
end
```

See the [Error Handling guide](/guides/advanced/errors) for more details.

## Use Cases

### Check Available Views

See what views are available on a board:

```ruby
response = client.board_view.query(
  args: { ids: [1234567890] },
  select: ["id", "name", "type"]
)

if response.success?
  boards = response.body.dig("data", "boards")
  views = boards.first&.dig("views") || []

  puts "Available Views:"
  views.each do |view|
    puts "  • #{view['name']}"
  end
end
```

### Find Default View

Get the main table view:

```ruby
response = client.board_view.query(
  args: { ids: [1234567890] },
  select: ["id", "name", "type"]
)

if response.success?
  boards = response.body.dig("data", "boards")
  views = boards.first&.dig("views") || []

  main_view = views.find { |v| v["type"] == "BoardView" }

  if main_view
    puts "Main View: #{main_view['name']} (ID: #{main_view['id']})"
  end
end
```

### Export View Information

Export view details for documentation:

```ruby
require "csv"

def export_views_to_csv(client, board_id, filename)
  response = client.board_view.query(
    args: { ids: [board_id] },
    select: ["id", "name", "type"]
  )

  return unless response.success?

  boards = response.body.dig("data", "boards")
  views = boards.first&.dig("views") || []

  CSV.open(filename, "w") do |csv|
    csv << ["ID", "Name", "Type"]

    views.each do |view|
      csv << [view["id"], view["name"], view["type"]]
    end
  end

  puts "✓ Exported #{views.length} views to #{filename}"
end

# Usage
export_views_to_csv(client, 1234567890, "board_views.csv")
```

## Related Resources

- [Board](/reference/resources/board) - Boards containing views
- [Item](/reference/resources/item) - Items displayed in views
- [Column](/reference/resources/column) - Columns shown in views

## External References

- [monday.com Views API](https://developer.monday.com/api-reference/reference/views)
- [GraphQL API Overview](https://developer.monday.com/api-reference/docs/introduction-to-graphql)
- [View Types](https://support.monday.com/hc/en-us/articles/115005571189-An-Overview-of-monday-com-Views)
