# Query Column Values

Retrieve column information and values from your boards.

## Query Board Columns

Get all columns for a board:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.column.query(
  args: { ids: [1234567890] }  # Board ID
)

if response.success?
  boards = response.body.dig("data", "boards")
  columns = boards.first&.dig("columns") || []

  puts "Found #{columns.length} columns:"
  columns.each do |column|
    puts "  • #{column['title']}: '#{column['id']}' (#{column['type']})"
  end
end
```

**Output:**
```
Found 7 columns:
  • Name: 'name' (name)
  • Status: 'status' (color)
  • Owner: 'people' (people)
  • Due Date: 'date4' (date)
  • Priority: 'status_1' (color)
  • Text: 'text' (text)
  • Budget: 'numbers' (numbers)
```

## Query Column Details

Get detailed column information:

```ruby
response = client.column.query(
  args: { ids: [1234567890] },
  select: [
    "id",
    "title",
    "description",
    "type",
    "width",
    "settings_str",
    "archived"
  ]
)

if response.success?
  boards = response.body.dig("data", "boards")
  columns = boards.first&.dig("columns") || []

  columns.each do |column|
    puts "\n#{column['title']}"
    puts "  ID: #{column['id']}"
    puts "  Type: #{column['type']}"
    puts "  Width: #{column['width']}"
    puts "  Archived: #{column['archived']}"
    puts "  Description: #{column['description']}" if column['description']
  end
end
```

## Query Multiple Boards

Get columns for multiple boards:

```ruby
response = client.column.query(
  args: { ids: [1234567890, 2345678901] },
  select: ["id", "title", "type"]
)

if response.success?
  boards = response.body.dig("data", "boards")

  boards.each do |board|
    columns = board["columns"] || []
    puts "\nBoard #{board['id']} has #{columns.length} columns"

    columns.each do |column|
      puts "  • #{column['title']} (#{column['type']})"
    end
  end
end
```

## Find Column by Title

Search for a column by its title:

```ruby
def find_column_by_title(client, board_id, title)
  response = client.column.query(
    args: { ids: [board_id] },
    select: ["id", "title", "type"]
  )

  return nil unless response.success?

  boards = response.body.dig("data", "boards")
  columns = boards.first&.dig("columns") || []

  columns.find { |col| col["title"].downcase == title.downcase }
end

# Usage
column = find_column_by_title(client, 1234567890, "Status")

if column
  puts "Found: #{column['title']}"
  puts "  ID: #{column['id']}"
  puts "  Type: #{column['type']}"
else
  puts "Column not found"
end
```

## Get Column ID by Title

Quickly get a column's ID:

```ruby
def get_column_id(client, board_id, title)
  column = find_column_by_title(client, board_id, title)
  column&.dig("id")
end

# Usage
column_id = get_column_id(client, 1234567890, "Status")
puts "Status column ID: #{column_id}"  # => status
```

## Filter Columns by Type

Find all columns of a specific type:

```ruby
def find_columns_by_type(client, board_id, column_type)
  response = client.column.query(
    args: { ids: [board_id] },
    select: ["id", "title", "type"]
  )

  return [] unless response.success?

  boards = response.body.dig("data", "boards")
  columns = boards.first&.dig("columns") || []

  columns.select { |col| col["type"] == column_type }
end

# Find all status columns
status_columns = find_columns_by_type(client, 1234567890, "color")

puts "Found #{status_columns.length} status columns:"
status_columns.each do |col|
  puts "  • #{col['title']} (#{col['id']})"
end
```

## Query Column Values for Items

Get column values for specific items:

```ruby
# Query items with their column values
response = client.item.query(
  args: { ids: [987654321, 987654322] },
  select: [
    "id",
    "name",
    {
      column_values: ["id", "text", "type", "value"]
    }
  ]
)

if response.success?
  items = response.body.dig("data", "items")

  items.each do |item|
    puts "\n#{item['name']}"
    puts "Column Values:"

    item["column_values"].each do |col_val|
      next if col_val["text"].nil? || col_val["text"].empty?
      puts "  • #{col_val['id']}: #{col_val['text']} (#{col_val['type']})"
    end
  end
end
```

## Parse Column Settings

Extract column settings (e.g., status labels):

```ruby
require "json"

response = client.column.query(
  args: { ids: [1234567890] },
  select: ["id", "title", "type", "settings_str"]
)

if response.success?
  boards = response.body.dig("data", "boards")
  columns = boards.first&.dig("columns") || []

  columns.each do |column|
    next unless column["settings_str"]

    settings = JSON.parse(column["settings_str"])

    puts "\n#{column['title']} (#{column['type']})"
    puts "  Settings: #{settings.keys.join(', ')}"

    # For status columns, show labels
    if column["type"] == "color" && settings["labels"]
      puts "  Labels:"
      settings["labels"].each do |id, label|
        puts "    #{id}: #{label}"
      end
    end
  end
end
```

## Get Column Structure

Build a map of column IDs to titles:

```ruby
def get_column_map(client, board_id)
  response = client.column.query(
    args: { ids: [board_id] },
    select: ["id", "title", "type"]
  )

  return {} unless response.success?

  boards = response.body.dig("data", "boards")
  columns = boards.first&.dig("columns") || []

  columns.each_with_object({}) do |col, hash|
    hash[col["id"]] = {
      title: col["title"],
      type: col["type"]
    }
  end
end

# Usage
column_map = get_column_map(client, 1234567890)

puts "Column Map:"
column_map.each do |id, info|
  puts "  #{id} => #{info[:title]} (#{info[:type]})"
end
```

## Query Archived Columns

Find archived columns:

```ruby
response = client.column.query(
  args: { ids: [1234567890] },
  select: ["id", "title", "type", "archived"]
)

if response.success?
  boards = response.body.dig("data", "boards")
  columns = boards.first&.dig("columns") || []

  archived = columns.select { |col| col["archived"] }

  if archived.any?
    puts "Archived columns:"
    archived.each do |col|
      puts "  • #{col['title']} (#{col['id']})"
    end
  else
    puts "No archived columns"
  end
end
```

## Export Column Structure to CSV

Export column information:

```ruby
require "csv"

def export_columns_to_csv(client, board_id, filename)
  response = client.column.query(
    args: { ids: [board_id] },
    select: ["id", "title", "type", "description", "width"]
  )

  return unless response.success?

  boards = response.body.dig("data", "boards")
  columns = boards.first&.dig("columns") || []

  CSV.open(filename, "w") do |csv|
    # Header
    csv << ["ID", "Title", "Type", "Description", "Width"]

    # Data
    columns.each do |column|
      csv << [
        column["id"],
        column["title"],
        column["type"],
        column["description"] || "",
        column["width"]
      ]
    end
  end

  puts "✓ Exported #{columns.length} columns to #{filename}"
end

# Usage
export_columns_to_csv(client, 1234567890, "board_columns.csv")
```

## Complete Example

Comprehensive column querying:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

board_id = 1234567890

response = client.column.query(
  args: { ids: [board_id] },
  select: [
    "id",
    "title",
    "description",
    "type",
    "width",
    "archived"
  ]
)

if response.success?
  boards = response.body.dig("data", "boards")
  columns = boards.first&.dig("columns") || []

  puts "\n📊 Board Column Structure\n#{'=' * 60}\n"
  puts "Total columns: #{columns.length}"

  # Group by type
  by_type = columns.group_by { |col| col["type"] }

  puts "\nColumns by Type:"
  by_type.each do |type, cols|
    puts "  #{type}: #{cols.length} column(s)"
  end

  puts "\n#{'=' * 60}\n"
  puts "Column Details:\n"

  columns.each_with_index do |column, index|
    puts "\n#{index + 1}. #{column['title']}"
    puts "   ID: #{column['id']}"
    puts "   Type: #{column['type']}"
    puts "   Width: #{column['width']}"
    puts "   Archived: #{column['archived']}"
    puts "   Description: #{column['description']}" if column['description']
  end

  puts "\n#{'=' * 60}"
else
  puts "❌ Failed to query columns"
  puts "Status: #{response.status}"
end
```

**Output:**
```
📊 Board Column Structure
============================================================

Total columns: 8

Columns by Type:
  name: 1 column(s)
  color: 2 column(s)
  people: 1 column(s)
  date: 1 column(s)
  text: 1 column(s)
  numbers: 1 column(s)
  long-text: 1 column(s)

============================================================

Column Details:

1. Name
   ID: name
   Type: name
   Width: 250
   Archived: false

2. Status
   ID: status
   Type: color
   Width: 120
   Archived: false
   Description: Current status of the task

3. Owner
   ID: people
   Type: people
   Width: 150
   Archived: false

...

============================================================
```

## Next Steps

- [Create columns](/guides/columns/create)
- [Update column values](/guides/columns/update-values)
- [Change column metadata](/guides/columns/metadata)
- [Query items](/guides/items/query)
