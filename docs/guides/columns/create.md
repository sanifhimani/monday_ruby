# Create Columns

Add new columns to your monday.com boards to track different types of information.

## Basic Column Creation

Create a simple text column:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.column.create(
  args: {
    board_id: 1234567890,
    title: "Notes",
    column_type: :text
  }
)

if response.success?
  column = response.body.dig("data", "create_column")
  puts "✓ Created column: #{column['title']}"
  puts "  ID: #{column['id']}"
else
  puts "✗ Failed to create column"
end
```

**Output:**
```
✓ Created column: Notes
  ID: text_1
```

## Column Types

monday.com supports many column types:

### Text Column

```ruby
response = client.column.create(
  args: {
    board_id: 1234567890,
    title: "Description",
    column_type: :text
  }
)
```

### Status Column

```ruby
response = client.column.create(
  args: {
    board_id: 1234567890,
    title: "Status",
    column_type: :color  # Status columns use type 'color'
  }
)
```

### Date Column

```ruby
response = client.column.create(
  args: {
    board_id: 1234567890,
    title: "Due Date",
    column_type: :date
  }
)
```

### People Column

```ruby
response = client.column.create(
  args: {
    board_id: 1234567890,
    title: "Assignee",
    column_type: :people
  }
)
```

### Numbers Column

```ruby
response = client.column.create(
  args: {
    board_id: 1234567890,
    title: "Budget",
    column_type: :numbers
  }
)
```

### Timeline Column

```ruby
response = client.column.create(
  args: {
    board_id: 1234567890,
    title: "Project Timeline",
    column_type: :timeline
  }
)
```

## Available Column Types

| Type | Description | monday.com Name |
|------|-------------|-----------------|
| `:text` | Short text | Text |
| `:long_text` | Long text with formatting | Long Text |
| `:color` | Status with labels | Status |
| `:date` | Date and time | Date |
| `:people` | Person or team | People |
| `:numbers` | Numeric values | Numbers |
| `:timeline` | Date range | Timeline |
| `:dropdown` | Dropdown selection | Dropdown |
| `:email` | Email address | Email |
| `:phone` | Phone number | Phone |
| `:link` | URL | Link |
| `:checkbox` | Checkbox | Checkbox |
| `:rating` | Star rating | Rating |
| `:hour` | Time tracking | Hour |
| `:week` | Week selector | Week |
| `:country` | Country selector | Country |
| `:file` | File attachment | Files |
| `:location` | Geographic location | Location |
| `:tag` | Tags | Tags |

## Create with Description

Add a description to help users understand the column:

```ruby
response = client.column.create(
  args: {
    board_id: 1234567890,
    title: "Priority",
    column_type: :color,
    description: "Task priority level (High, Medium, Low)"
  }
)

if response.success?
  column = response.body.dig("data", "create_column")
  puts "Created: #{column['title']}"
  puts "Description: #{column['description']}"
end
```

## Create with Default Values

Set default values for status columns:

```ruby
require "json"

# Define status labels
defaults = JSON.generate({
  labels: {
    "0": "Not Started",
    "1": "In Progress",
    "2": "Done"
  }
})

response = client.column.create(
  args: {
    board_id: 1234567890,
    title: "Status",
    column_type: :color,
    defaults: defaults
  }
)
```

## Customize Response Fields

Get additional column information:

```ruby
response = client.column.create(
  args: {
    board_id: 1234567890,
    title: "Priority",
    column_type: :color
  },
  select: [
    "id",
    "title",
    "description",
    "type",
    "width",
    "settings_str"
  ]
)

if response.success?
  column = response.body.dig("data", "create_column")

  puts "Column Details:"
  puts "  ID: #{column['id']}"
  puts "  Title: #{column['title']}"
  puts "  Type: #{column['type']}"
  puts "  Width: #{column['width']}"
end
```

## Create Multiple Columns

Set up a board structure with multiple columns:

```ruby
board_id = 1234567890

columns_to_create = [
  { title: "Task Name", column_type: :text },
  { title: "Status", column_type: :color },
  { title: "Owner", column_type: :people },
  { title: "Due Date", column_type: :date },
  { title: "Priority", column_type: :color },
  { title: "Budget", column_type: :numbers }
]

created_columns = []

columns_to_create.each do |col_config|
  response = client.column.create(
    args: {
      board_id: board_id,
      **col_config
    }
  )

  if response.success?
    column = response.body.dig("data", "create_column")
    created_columns << column
    puts "✓ Created: #{column['title']} (#{column['type']})"
  else
    puts "✗ Failed to create: #{col_config[:title]}"
  end

  sleep(0.3)  # Rate limiting
end

puts "\n✓ Created #{created_columns.length} columns"
```

**Output:**
```
✓ Created: Task Name (text)
✓ Created: Status (color)
✓ Created: Owner (people)
✓ Created: Due Date (date)
✓ Created: Priority (color)
✓ Created: Budget (numbers)

✓ Created 6 columns
```

## Error Handling

Handle common column creation errors:

```ruby
def create_column_safe(client, board_id, title, column_type)
  response = client.column.create(
    args: {
      board_id: board_id,
      title: title,
      column_type: column_type
    }
  )

  if response.success?
    column = response.body.dig("data", "create_column")
    puts "✓ Created: #{column['title']} (ID: #{column['id']})"
    column['id']
  else
    puts "✗ Failed to create column: #{title}"
    puts "  Status: #{response.status}"

    if response.body["errors"]
      response.body["errors"].each do |error|
        puts "  Error: #{error['message']}"
      end
    end

    nil
  end
rescue Monday::AuthorizationError
  puts "✗ Invalid API token"
  nil
rescue Monday::InvalidRequestError => e
  puts "✗ Invalid board ID: #{e.message}"
  nil
rescue Monday::Error => e
  puts "✗ API error: #{e.message}"
  nil
end

# Usage
column_id = create_column_safe(client, 1234567890, "Status", :color)
```

## Validate Column Title

Check for valid column titles:

```ruby
def valid_column_title?(title)
  return false if title.nil? || title.empty?
  return false if title.length > 255

  true
end

title = "Priority Level"

if valid_column_title?(title)
  response = client.column.create(
    args: {
      board_id: 1234567890,
      title: title,
      column_type: :color
    }
  )
else
  puts "Invalid column title"
end
```

## Complete Example

Create a full project board structure:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

board_id = 1234567890

# Define board structure
board_structure = [
  {
    title: "Status",
    column_type: :color,
    description: "Current status of the task"
  },
  {
    title: "Owner",
    column_type: :people,
    description: "Person responsible for this task"
  },
  {
    title: "Priority",
    column_type: :color,
    description: "Task priority (High, Medium, Low)"
  },
  {
    title: "Due Date",
    column_type: :date,
    description: "When this task is due"
  },
  {
    title: "Budget",
    column_type: :numbers,
    description: "Estimated budget for this task"
  },
  {
    title: "Notes",
    column_type: :long_text,
    description: "Additional notes and comments"
  }
]

puts "\n📋 Creating Board Structure\n#{'=' * 50}\n"

created_columns = []

board_structure.each do |col_config|
  response = client.column.create(
    args: {
      board_id: board_id,
      **col_config
    },
    select: ["id", "title", "type", "description"]
  )

  if response.success?
    column = response.body.dig("data", "create_column")
    created_columns << column

    puts "✓ #{column['title']}"
    puts "  Type: #{column['type']}"
    puts "  ID: #{column['id']}"
    puts "  Description: #{column['description']}\n\n"
  else
    puts "✗ Failed to create: #{col_config[:title]}"
  end

  sleep(0.3)
end

puts "#{'=' * 50}"
puts "✓ Created #{created_columns.length} columns"
puts "#{'=' * 50}"
```

## Delete a Column

Remove a column from a board:

```ruby
response = client.column.delete(
  1234567890,  # board_id
  "text_1"     # column_id
)

if response.success?
  column = response.body.dig("data", "delete_column")
  puts "✓ Deleted column ID: #{column['id']}"
end
```

:::warning Permanent Deletion
Deleting a column removes it and all its data from every item on the board. This cannot be undone.
:::
