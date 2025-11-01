# Change Column Metadata

Update column settings, titles, and configuration.

## Change Column Title

Rename a column:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.column.change_title(
  args: {
    board_id: 1234567890,
    column_id: "text_1",  # The column's ID
    title: "Project Notes"  # New title
  }
)

if response.success?
  column = response.body.dig("data", "change_column_title")
  puts "✓ Column renamed to: #{column['title']}"
else
  puts "✗ Failed to rename column"
end
```

**Output:**
```
✓ Column renamed to: Project Notes
```

## Change Column Metadata

Update column settings and configuration:

```ruby
require "json"

# Update column description
response = client.column.change_metadata(
  args: {
    board_id: 1234567890,
    column_id: "status",
    column_property: "description",
    value: "Current task status (Not Started, In Progress, Done)"
  }
)

if response.success?
  column = response.body.dig("data", "change_column_metadata")
  puts "✓ Column metadata updated"
end
```

## Update Column Description

Add or update a column's description:

```ruby
def update_column_description(client, board_id, column_id, description)
  response = client.column.change_metadata(
    args: {
      board_id: board_id,
      column_id: column_id,
      column_property: "description",
      value: description
    }
  )

  if response.success?
    column = response.body.dig("data", "change_column_metadata")
    puts "✓ Description updated for: #{column['title']}"
    true
  else
    puts "✗ Failed to update description"
    false
  end
end

# Usage
update_column_description(
  client,
  1234567890,
  "status",
  "Track task completion status"
)
```

## Update Status Column Labels

Configure status (color) column labels:

```ruby
# First, get current column settings
query_response = client.column.query(
  args: { ids: [1234567890] },
  select: ["id", "title", "settings_str"]
)

boards = query_response.body.dig("data", "boards")
columns = boards.first&.dig("columns") || []
status_column = columns.find { |col| col["id"] == "status" }

# Parse current settings
current_settings = JSON.parse(status_column["settings_str"])

# Modify labels
current_settings["labels"] = {
  "0" => "Not Started",
  "1" => "In Progress",
  "2" => "Review",
  "3" => "Done",
  "4" => "Archived"
}

# Update column metadata
response = client.column.change_metadata(
  args: {
    board_id: 1234567890,
    column_id: "status",
    column_property: "labels",
    value: JSON.generate(current_settings["labels"])
  }
)

if response.success?
  puts "✓ Status labels updated"
end
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Column Settings</span>
Different column types have different metadata properties. Use `column.query` with `settings_str` to see available options for each column type.
:::

## Rename Multiple Columns

Update titles for several columns:

```ruby
def rename_columns(client, board_id, renames)
  updated_count = 0

  renames.each do |column_id, new_title|
    response = client.column.change_title(
      args: {
        board_id: board_id,
        column_id: column_id,
        title: new_title
      }
    )

    if response.success?
      column = response.body.dig("data", "change_column_title")
      updated_count += 1
      puts "✓ Renamed: #{column['title']}"
    else
      puts "✗ Failed to rename: #{column_id}"
    end

    sleep(0.3)  # Rate limiting
  end

  updated_count
end

# Usage
renames = {
  "text" => "Task Description",
  "numbers" => "Estimated Hours",
  "date4" => "Target Completion"
}

count = rename_columns(client, 1234567890, renames)
puts "\n✓ Renamed #{count} columns"
```

## Update Dropdown Options

Modify dropdown column options:

```ruby
require "json"

# Define new dropdown options
dropdown_labels = {
  "1" => "High Priority",
  "2" => "Medium Priority",
  "3" => "Low Priority",
  "4" => "No Priority"
}

response = client.column.change_metadata(
  args: {
    board_id: 1234567890,
    column_id: "dropdown",
    column_property: "labels",
    value: JSON.generate(dropdown_labels)
  }
)

if response.success?
  puts "✓ Dropdown options updated"
end
```

## Add Column Descriptions in Bulk

Add helpful descriptions to all columns:

```ruby
def add_column_descriptions(client, board_id, descriptions)
  updated_count = 0

  descriptions.each do |column_id, description|
    response = client.column.change_metadata(
      args: {
        board_id: board_id,
        column_id: column_id,
        column_property: "description",
        value: description
      }
    )

    if response.success?
      updated_count += 1
      puts "✓ Updated: #{column_id}"
    else
      puts "✗ Failed: #{column_id}"
    end

    sleep(0.3)
  end

  updated_count
end

# Usage
descriptions = {
  "status" => "Current status of the task",
  "people" => "Person responsible for this task",
  "date4" => "When this task is due",
  "numbers" => "Estimated budget in USD"
}

count = add_column_descriptions(client, 1234567890, descriptions)
puts "\n✓ Added descriptions to #{count} columns"
```

## Error Handling

Handle metadata update errors:

```ruby
def change_column_title_safe(client, board_id, column_id, new_title)
  response = client.column.change_title(
    args: {
      board_id: board_id,
      column_id: column_id,
      title: new_title
    }
  )

  if response.success?
    column = response.body.dig("data", "change_column_title")
    puts "✓ Renamed to: #{column['title']}"
    true
  else
    puts "✗ Failed to rename column"
    puts "  Status: #{response.status}"

    if response.body["errors"]
      response.body["errors"].each do |error|
        puts "  Error: #{error['message']}"
      end
    end

    false
  end
rescue Monday::AuthorizationError
  puts "✗ Invalid API token"
  false
rescue Monday::InvalidRequestError => e
  puts "✗ Invalid request: #{e.message}"
  false
rescue Monday::Error => e
  puts "✗ API error: #{e.message}"
  false
end

# Usage
success = change_column_title_safe(
  client,
  1234567890,
  "text",
  "New Column Name"
)
```

## Get Updated Column Info

Retrieve column details after update:

```ruby
response = client.column.change_title(
  args: {
    board_id: 1234567890,
    column_id: "text",
    title: "Project Description"
  },
  select: [
    "id",
    "title",
    "description",
    "type",
    "settings_str"
  ]
)

if response.success?
  column = response.body.dig("data", "change_column_title")

  puts "Column Updated:"
  puts "  ID: #{column['id']}"
  puts "  Title: #{column['title']}"
  puts "  Type: #{column['type']}"
  puts "  Description: #{column['description']}" if column['description']
end
```

## Complete Example

Set up complete column metadata:

```ruby
require "monday_ruby"
require "dotenv/load"
require "json"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

board_id = 1234567890

puts "\n📝 Configuring Board Columns\n#{'=' * 50}\n"

# 1. Rename columns
column_renames = {
  "text" => "Task Description",
  "numbers" => "Budget (USD)",
  "status" => "Task Status"
}

puts "Renaming columns..."
column_renames.each do |column_id, new_title|
  response = client.column.change_title(
    args: {
      board_id: board_id,
      column_id: column_id,
      title: new_title
    }
  )

  if response.success?
    puts "  ✓ #{column_id} → #{new_title}"
  end

  sleep(0.3)
end

# 2. Add descriptions
column_descriptions = {
  "text" => "Detailed description of the task and requirements",
  "numbers" => "Estimated budget in US Dollars",
  "status" => "Current completion status of the task",
  "people" => "Team member assigned to this task",
  "date4" => "Target completion date for this task"
}

puts "\nAdding descriptions..."
column_descriptions.each do |column_id, description|
  response = client.column.change_metadata(
    args: {
      board_id: board_id,
      column_id: column_id,
      column_property: "description",
      value: description
    }
  )

  if response.success?
    puts "  ✓ #{column_id}"
  end

  sleep(0.3)
end

# 3. Configure status labels
puts "\nConfiguring status labels..."
status_labels = {
  "0" => "Not Started",
  "1" => "Planning",
  "2" => "In Progress",
  "3" => "Review",
  "4" => "Done"
}

response = client.column.change_metadata(
  args: {
    board_id: board_id,
    column_id: "status",
    column_property: "labels",
    value: JSON.generate(status_labels)
  }
)

if response.success?
  puts "  ✓ Status labels configured"
end

puts "\n#{'=' * 50}"
puts "✓ Column configuration complete"
puts "#{'=' * 50}"
```

**Output:**
```
📝 Configuring Board Columns
==================================================

Renaming columns...
  ✓ text → Task Description
  ✓ numbers → Budget (USD)
  ✓ status → Task Status

Adding descriptions...
  ✓ text
  ✓ numbers
  ✓ status
  ✓ people
  ✓ date4

Configuring status labels...
  ✓ Status labels configured

==================================================
✓ Column configuration complete
==================================================
```

## Validate Column Title

Check for valid column titles before updating:

```ruby
def valid_column_title?(title)
  return false if title.nil? || title.empty?
  return false if title.length > 255

  true
end

new_title = "Updated Column Name"

if valid_column_title?(new_title)
  response = client.column.change_title(
    args: {
      board_id: 1234567890,
      column_id: "text",
      title: new_title
    }
  )
else
  puts "Invalid column title"
end
```

## Next Steps

- [Create columns](/guides/columns/create)
- [Update column values](/guides/columns/update-values)
- [Query column values](/guides/columns/query)
- [Query boards](/guides/boards/query)
