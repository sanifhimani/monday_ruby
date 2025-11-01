# Task Management System

Build a complete task management system using the monday_ruby gem. This guide demonstrates real-world usage patterns by creating a production-ready task tracker with proper structure, team assignments, status updates, and reporting.

## What You'll Build

A complete task management system that:
- Creates task boards with proper column structure
- Manages tasks across different project phases
- Assigns tasks to team members
- Tracks status and priority
- Adds comments and updates
- Generates completion reports

## Prerequisites

```ruby
# Gemfile
gem "monday_ruby"
gem "dotenv"

# .env file
MONDAY_TOKEN=your_api_token_here
```

Install dependencies:
```bash
bundle install
```

## Complete Working Example

Here's a full task management system implementation. Copy and run this code:

```ruby
#!/usr/bin/env ruby
# task_manager.rb

require "monday_ruby"
require "dotenv/load"
require "json"
require "date"

# Configure the client
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

class TaskManager
  attr_reader :client, :board_id

  def initialize
    @client = Monday::Client.new
    @board_id = nil
  end

  # Step 1: Setup - Create a task board with proper structure
  def setup_task_board
    puts "\n" + "=" * 70
    puts "STEP 1: Setting Up Task Board"
    puts "=" * 70

    # Create the board
    response = client.board.create(
      args: {
        board_name: "Project Tasks - #{Date.today}",
        board_kind: :public,
        description: "Task management board for team collaboration"
      },
      select: ["id", "name", "description"]
    )

    unless response.success?
      handle_error("Failed to create board", response)
      return false
    end

    board = response.body.dig("data", "create_board")
    @board_id = board["id"].to_i

    puts "✓ Created board: #{board['name']}"
    puts "  ID: #{@board_id}"
    puts "  Description: #{board['description']}"

    # Create task management columns
    create_task_columns

    # Create groups for project phases
    create_project_groups

    true
  end

  # Create columns for task management
  def create_task_columns
    puts "\nCreating task management columns..."

    columns = [
      {
        title: "Status",
        column_type: :status,
        description: "Task status"
      },
      {
        title: "Owner",
        column_type: :people,
        description: "Task assignee"
      },
      {
        title: "Due Date",
        column_type: :date,
        description: "Task deadline"
      },
      {
        title: "Priority",
        column_type: :status,
        description: "Task priority level"
      },
      {
        title: "Notes",
        column_type: :text,
        description: "Additional notes"
      }
    ]

    columns.each do |col|
      response = client.column.create(
        args: {
          board_id: @board_id,
          title: col[:title],
          column_type: col[:column_type],
          description: col[:description]
        },
        select: ["id", "title", "type"]
      )

      if response.success?
        column = response.body.dig("data", "create_column")
        puts "  ✓ Created column: #{column['title']} (#{column['type']})"
      else
        puts "  ✗ Failed to create column: #{col[:title]}"
      end

      # Rate limiting: avoid hitting API limits
      sleep(0.3)
    end
  end

  # Create groups for different project phases
  def create_project_groups
    puts "\nCreating project phase groups..."

    groups = [
      { name: "Planning", color: "#579bfc" },
      { name: "In Progress", color: "#fdab3d" },
      { name: "Review", color: "#a25ddc" },
      { name: "Completed", color: "#00c875" }
    ]

    groups.each do |group_data|
      response = client.group.create(
        args: {
          board_id: @board_id,
          group_name: group_data[:name]
        },
        select: ["id", "title"]
      )

      if response.success?
        group = response.body.dig("data", "create_group")
        puts "  ✓ Created group: #{group['title']}"
      end

      sleep(0.3)
    end
  end

  # Step 2: Get board structure (column IDs)
  def get_board_structure
    puts "\n" + "=" * 70
    puts "STEP 2: Retrieving Board Structure"
    puts "=" * 70

    response = client.board.query(
      args: { ids: [@board_id] },
      select: [
        "id",
        "name",
        {
          columns: ["id", "title", "type"],
          groups: ["id", "title"]
        }
      ]
    )

    unless response.success?
      handle_error("Failed to get board structure", response)
      return nil
    end

    board = response.body.dig("data", "boards", 0)

    puts "\nBoard: #{board['name']}"
    puts "\nColumns:"
    board["columns"].each do |col|
      puts "  • #{col['title']}: '#{col['id']}' (#{col['type']})"
    end

    puts "\nGroups:"
    board["groups"].each do |group|
      puts "  • #{group['title']}: '#{group['id']}'"
    end

    board
  end

  # Step 3: Create tasks with proper fields
  def create_tasks(board_structure)
    puts "\n" + "=" * 70
    puts "STEP 3: Creating Tasks"
    puts "=" * 70

    # Extract column IDs (these will be dynamic based on board)
    columns = board_structure["columns"].each_with_object({}) do |col, hash|
      hash[col["title"].downcase.gsub(" ", "_")] = col["id"]
    end

    # Get the first group (Planning)
    planning_group = board_structure["groups"].find { |g| g["title"] == "Planning" }

    tasks = [
      {
        name: "Define project requirements",
        status: "Working on it",
        priority: "High",
        due_date: (Date.today + 7).to_s,
        notes: "Gather stakeholder requirements and create specification"
      },
      {
        name: "Design database schema",
        status: "Not Started",
        priority: "High",
        due_date: (Date.today + 10).to_s,
        notes: "Create ERD and define table structures"
      },
      {
        name: "Setup development environment",
        status: "Done",
        priority: "Medium",
        due_date: Date.today.to_s,
        notes: "Configure local environment and CI/CD pipeline"
      },
      {
        name: "Write API documentation",
        status: "Not Started",
        priority: "Medium",
        due_date: (Date.today + 14).to_s,
        notes: "Document all API endpoints and authentication"
      }
    ]

    created_items = []

    tasks.each do |task|
      # Build column values
      column_values = {}

      # Status column
      if columns["status"]
        column_values[columns["status"]] = { label: task[:status] }
      end

      # Priority column
      if columns["priority"]
        column_values[columns["priority"]] = { label: task[:priority] }
      end

      # Due date column
      if columns["due_date"]
        column_values[columns["due_date"]] = { date: task[:due_date] }
      end

      # Notes column
      if columns["notes"]
        column_values[columns["notes"]] = task[:notes]
      end

      response = client.item.create(
        args: {
          board_id: @board_id,
          group_id: planning_group["id"],
          item_name: task[:name],
          column_values: column_values,
          create_labels_if_missing: true
        },
        select: [
          "id",
          "name",
          {
            group: ["id", "title"],
            column_values: ["id", "text"]
          }
        ]
      )

      if response.success?
        item = response.body.dig("data", "create_item")
        created_items << item
        puts "✓ Created task: #{item['name']}"
        puts "  ID: #{item['id']}"
        puts "  Group: #{item.dig('group', 'title')}"
      else
        puts "✗ Failed to create task: #{task[:name]}"
        handle_error("", response)
      end

      sleep(0.5)
    end

    created_items
  end

  # Step 4: Assign tasks to team members
  def assign_tasks(items, team_member_id)
    puts "\n" + "=" * 70
    puts "STEP 4: Assigning Tasks to Team Members"
    puts "=" * 70

    unless team_member_id
      puts "⚠ No team member ID provided. Skipping assignments."
      puts "  To assign tasks, provide a user ID from your workspace."
      return
    end

    # Get the owner column ID first
    response = client.board.query(
      args: { ids: [@board_id] },
      select: [
        {
          columns: ["id", "title", "type"]
        }
      ]
    )

    return unless response.success?

    board = response.body.dig("data", "boards", 0)
    owner_column = board["columns"].find { |c| c["title"] == "Owner" }

    unless owner_column
      puts "⚠ Owner column not found"
      return
    end

    # Assign first two tasks
    items.first(2).each do |item|
      response = client.column.change_value(
        args: {
          board_id: @board_id,
          item_id: item["id"].to_i,
          column_id: owner_column["id"],
          value: {
            personsAndTeams: [
              { id: team_member_id.to_i, kind: "person" }
            ]
          }
        },
        select: ["id", "name"]
      )

      if response.success?
        updated_item = response.body.dig("data", "change_column_value")
        puts "✓ Assigned task to team member: #{updated_item['name']}"
      else
        puts "✗ Failed to assign: #{item['name']}"
      end

      sleep(0.5)
    end
  end

  # Step 5: Update task status
  def update_task_status(items)
    puts "\n" + "=" * 70
    puts "STEP 5: Updating Task Status"
    puts "=" * 70

    # Get column structure
    response = client.board.query(
      args: { ids: [@board_id] },
      select: [
        {
          columns: ["id", "title", "type"],
          groups: ["id", "title"]
        }
      ]
    )

    return unless response.success?

    board = response.body.dig("data", "boards", 0)
    status_column = board["columns"].find { |c| c["title"] == "Status" }
    in_progress_group = board["groups"].find { |g| g["title"] == "In Progress" }

    # Move first task to "In Progress" and update status
    if items.any? && status_column && in_progress_group
      task = items.first

      # Update status and move to group using change_multiple_values
      response = client.column.change_multiple_values(
        args: {
          board_id: @board_id,
          item_id: task["id"].to_i,
          column_values: {
            status_column["id"] => { label: "Working on it" }
          }
        },
        select: ["id", "name"]
      )

      if response.success?
        puts "✓ Updated status to 'Working on it': #{task['name']}"

        # Move to In Progress group
        move_response = client.group.move_item(
          args: {
            item_id: task["id"].to_i,
            group_id: in_progress_group["id"]
          },
          select: ["id"]
        )

        if move_response.success?
          puts "✓ Moved to 'In Progress' group"
        end
      end

      sleep(0.5)

      # Complete the third task
      if items.length > 2
        completed_task = items[2]
        completed_group = board["groups"].find { |g| g["title"] == "Completed" }

        response = client.column.change_multiple_values(
          args: {
            board_id: @board_id,
            item_id: completed_task["id"].to_i,
            column_values: {
              status_column["id"] => { label: "Done" }
            }
          },
          select: ["id", "name"]
        )

        if response.success?
          puts "✓ Marked as complete: #{completed_task['name']}"

          if completed_group
            client.group.move_item(
              args: {
                item_id: completed_task["id"].to_i,
                group_id: completed_group["id"]
              }
            )
            puts "✓ Moved to 'Completed' group"
          end
        end
      end
    end
  end

  # Step 6: Add comments and updates to tasks
  def add_task_updates(items)
    puts "\n" + "=" * 70
    puts "STEP 6: Adding Comments and Updates"
    puts "=" * 70

    updates = [
      {
        item: items.first,
        text: "Started gathering requirements from stakeholders. Initial meeting scheduled for tomorrow."
      },
      {
        item: items[1],
        text: "Reviewed existing schema. Planning to add new tables for user preferences and audit logs."
      }
    ]

    updates.each do |update_data|
      next unless update_data[:item]

      response = client.update.create(
        args: {
          item_id: update_data[:item]["id"].to_i,
          body: update_data[:text]
        },
        select: ["id", "body", "created_at"]
      )

      if response.success?
        update = response.body.dig("data", "create_update")
        puts "✓ Added update to: #{update_data[:item]['name']}"
        puts "  Comment: #{update['body'][0..60]}..."
      else
        puts "✗ Failed to add update"
      end

      sleep(0.5)
    end
  end

  # Step 7: Query and filter tasks
  def query_tasks
    puts "\n" + "=" * 70
    puts "STEP 7: Querying and Filtering Tasks"
    puts "=" * 70

    # Get all tasks with full details
    response = client.board.items_page(
      board_ids: @board_id,
      limit: 100,
      select: [
        "id",
        "name",
        "state",
        "created_at",
        {
          group: ["id", "title"],
          column_values: ["id", "text", "type"],
          updates: ["id", "body", "created_at"]
        }
      ]
    )

    unless response.success?
      handle_error("Failed to query tasks", response)
      return
    end

    board = response.body.dig("data", "boards", 0)
    items = board.dig("items_page", "items") || []

    puts "\nAll Tasks (#{items.length}):"
    items.each do |item|
      group = item.dig("group", "title")
      status = item["column_values"].find { |cv| cv["id"].include?("status") }
      due_date = item["column_values"].find { |cv| cv["type"] == "date" }
      updates_count = item["updates"]&.length || 0

      puts "\n  #{item['name']}"
      puts "    Group: #{group}"
      puts "    Status: #{status&.dig('text') || 'N/A'}"
      puts "    Due Date: #{due_date&.dig('text') || 'N/A'}"
      puts "    Updates: #{updates_count}"
    end

    items
  end

  # Step 8: Find overdue tasks
  def find_overdue_tasks(items)
    puts "\n" + "=" * 70
    puts "STEP 8: Finding Overdue Tasks"
    puts "=" * 70

    overdue = []

    items.each do |item|
      date_column = item["column_values"].find { |cv| cv["type"] == "date" }
      next unless date_column && date_column["text"]

      # Parse date from text (format: "2024-12-31")
      begin
        due_date_text = date_column["text"]
        # Handle both date and datetime formats
        due_date = Date.parse(due_date_text.split(" ").first)

        if due_date < Date.today
          overdue << {
            item: item,
            due_date: due_date,
            days_overdue: (Date.today - due_date).to_i
          }
        end
      rescue Date::Error
        # Skip invalid dates
        next
      end
    end

    if overdue.any?
      puts "\nOverdue Tasks (#{overdue.length}):"
      overdue.sort_by { |t| t[:days_overdue] }.reverse.each do |task|
        puts "\n  ⚠ #{task[:item]['name']}"
        puts "    Due: #{task[:due_date]}"
        puts "    Overdue by: #{task[:days_overdue]} day(s)"
      end
    else
      puts "\n✓ No overdue tasks!"
    end

    overdue
  end

  # Step 9: Generate completion report
  def generate_report(items)
    puts "\n" + "=" * 70
    puts "STEP 9: Generating Task Completion Report"
    puts "=" * 70

    # Group by status
    by_status = items.group_by do |item|
      status_col = item["column_values"].find { |cv| cv["id"].include?("status") }
      status_col&.dig("text") || "No Status"
    end

    # Group by priority
    by_priority = items.group_by do |item|
      # Find the second status column (Priority)
      priority_col = item["column_values"].select { |cv| cv["type"] == "color" }[1]
      priority_col&.dig("text") || "No Priority"
    end

    # Group by group (project phase)
    by_group = items.group_by do |item|
      item.dig("group", "title") || "Unknown"
    end

    total = items.length
    completed = by_status["Done"]&.length || 0
    completion_rate = total > 0 ? (completed.to_f / total * 100).round(1) : 0

    puts "\nTask Summary:"
    puts "  Total Tasks: #{total}"
    puts "  Completed: #{completed}"
    puts "  Completion Rate: #{completion_rate}%"

    puts "\nBy Status:"
    by_status.sort_by { |status, _| status }.each do |status, tasks|
      puts "  #{status}: #{tasks.length}"
    end

    puts "\nBy Priority:"
    by_priority.sort_by { |priority, _| priority }.each do |priority, tasks|
      puts "  #{priority}: #{tasks.length}"
    end

    puts "\nBy Project Phase:"
    by_group.sort_by { |group, _| group }.each do |group, tasks|
      puts "  #{group}: #{tasks.length}"
    end

    {
      total: total,
      completed: completed,
      completion_rate: completion_rate,
      by_status: by_status,
      by_priority: by_priority,
      by_group: by_group
    }
  end

  # Step 10: Cleanup (optional)
  def cleanup
    puts "\n" + "=" * 70
    puts "STEP 10: Cleanup"
    puts "=" * 70

    print "\nDelete the task board? (y/N): "
    answer = gets.chomp.downcase

    if answer == "y"
      response = client.board.delete(@board_id)

      if response.success?
        puts "✓ Board deleted successfully"
      else
        puts "✗ Failed to delete board"
      end
    else
      puts "Board kept. ID: #{@board_id}"
      puts "View at: https://monday.com/boards/#{@board_id}"
    end
  end

  # Error handling helper
  def handle_error(message, response)
    puts "✗ #{message}"
    puts "  Status: #{response.status}"

    if response.body["errors"]
      response.body["errors"].each do |error|
        puts "  Error: #{error['message']}"
      end
    elsif response.body["error_message"]
      puts "  Error: #{response.body['error_message']}"
    end
  end
end

# Main execution
def main
  puts "\n" + "🚀 TASK MANAGEMENT SYSTEM 🚀".center(70)

  manager = TaskManager.new

  # Step 1: Setup board
  return unless manager.setup_task_board

  # Step 2: Get board structure
  board_structure = manager.get_board_structure
  return unless board_structure

  # Step 3: Create tasks
  items = manager.create_tasks(board_structure)
  return if items.empty?

  # Step 4: Assign tasks (optional - requires user ID)
  # Get your user ID from: https://monday.com/account/profile
  # Uncomment and add your user ID:
  # team_member_id = 12345678
  # manager.assign_tasks(items, team_member_id)

  # Step 5: Update task status
  manager.update_task_status(items)

  # Step 6: Add updates
  manager.add_task_updates(items)

  # Step 7: Query all tasks
  all_items = manager.query_tasks
  return unless all_items

  # Step 8: Find overdue tasks
  manager.find_overdue_tasks(all_items)

  # Step 9: Generate report
  manager.generate_report(all_items)

  # Step 10: Cleanup (optional)
  manager.cleanup

  puts "\n" + "=" * 70
  puts "Task Management System Demo Complete!"
  puts "=" * 70
end

# Run the program
begin
  main
rescue Monday::AuthorizationError
  puts "\n✗ Authentication failed. Check your MONDAY_TOKEN in .env"
rescue Monday::Error => e
  puts "\n✗ API Error: #{e.message}"
rescue StandardError => e
  puts "\n✗ Unexpected error: #{e.message}"
  puts e.backtrace.first(5)
end
```

## Running the Example

Save the code above as `task_manager.rb` and run it:

```bash
ruby task_manager.rb
```

Expected output:
```
======================================================================
                   🚀 TASK MANAGEMENT SYSTEM 🚀
======================================================================

======================================================================
STEP 1: Setting Up Task Board
======================================================================
✓ Created board: Project Tasks - 2024-11-01
  ID: 1234567890
  Description: Task management board for team collaboration

Creating task management columns...
  ✓ Created column: Status (color)
  ✓ Created column: Owner (people)
  ✓ Created column: Due Date (date)
  ✓ Created column: Priority (color)
  ✓ Created column: Notes (text)

Creating project phase groups...
  ✓ Created group: Planning
  ✓ Created group: In Progress
  ✓ Created group: Review
  ✓ Created group: Completed

======================================================================
STEP 2: Retrieving Board Structure
======================================================================

Board: Project Tasks - 2024-11-01

Columns:
  • Name: 'name' (name)
  • Status: 'status' (color)
  • Owner: 'people' (people)
  • Due Date: 'date' (date)
  • Priority: 'status_1' (color)
  • Notes: 'text' (text)

Groups:
  • Planning: 'topics'
  • In Progress: 'group_12345'
  • Review: 'group_23456'
  • Completed: 'group_34567'

======================================================================
STEP 3: Creating Tasks
======================================================================
✓ Created task: Define project requirements
  ID: 987654321
  Group: Planning
✓ Created task: Design database schema
  ID: 987654322
  Group: Planning
✓ Created task: Setup development environment
  ID: 987654323
  Group: Planning
✓ Created task: Write API documentation
  ID: 987654324
  Group: Planning

... (continues with all steps)
```

## Key Patterns and Best Practices

### 1. Board Setup Pattern

Always create boards with proper structure:

```ruby
# Create board
board_response = client.board.create(
  args: {
    board_name: "Task Board",
    board_kind: :public,
    description: "Description here"
  }
)

board_id = board_response.body.dig("data", "create_board", "id").to_i

# Add columns
client.column.create(
  args: {
    board_id: board_id,
    title: "Status",
    column_type: :status
  }
)
```

### 2. Get Column IDs Before Setting Values

Column IDs are board-specific:

```ruby
response = client.board.query(
  args: { ids: [board_id] },
  select: [
    {
      columns: ["id", "title", "type"]
    }
  ]
)

board = response.body.dig("data", "boards", 0)
columns = board["columns"].each_with_object({}) do |col, hash|
  hash[col["title"].downcase] = col["id"]
end

# Now use actual column IDs
column_values = {
  columns["status"] => { label: "Working on it" }
}
```

### 3. Efficient Bulk Updates

Use `change_multiple_values` to update multiple columns at once:

```ruby
# Good - Single request
client.column.change_multiple_values(
  args: {
    board_id: board_id,
    item_id: item_id,
    column_values: {
      "status" => { label: "Done" },
      "priority" => { label: "High" },
      "date4" => { date: "2024-12-31" }
    }
  }
)

# Bad - Multiple requests
client.column.change_value(args: { column_id: "status", value: {...} })
client.column.change_value(args: { column_id: "priority", value: {...} })
client.column.change_value(args: { column_id: "date4", value: {...} })
```

### 4. Error Handling Pattern

Always check response status and handle errors:

```ruby
def safe_create_item(client, board_id, name, columns = {})
  response = client.item.create(
    args: {
      board_id: board_id,
      item_name: name,
      column_values: columns
    }
  )

  if response.success?
    item = response.body.dig("data", "create_item")
    puts "✓ Created: #{item['name']}"
    item
  else
    puts "✗ Failed to create: #{name}"

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
  puts "✗ Invalid request: #{e.message}"
  nil
rescue Monday::Error => e
  puts "✗ API error: #{e.message}"
  nil
end
```

### 5. Rate Limiting

Add delays between requests to avoid rate limits:

```ruby
tasks.each do |task|
  client.item.create(args: task_data)

  # Prevent rate limiting
  sleep(0.5)
end
```

### 6. Query Optimization

Select only needed fields:

```ruby
# Good - Minimal fields
response = client.item.query(
  args: { ids: item_ids },
  select: [
    "id",
    "name",
    {
      column_values: ["id", "text"]
    }
  ]
)

# Bad - Over-fetching
response = client.item.query(
  args: { ids: item_ids }
  # Uses all default fields plus unused nested data
)
```

## Advanced Use Cases

### Finding Tasks by Assignee

```ruby
def find_user_tasks(client, board_id, user_id)
  # Get all items
  response = client.board.items_page(
    board_ids: board_id,
    limit: 100,
    select: [
      "id",
      "name",
      {
        column_values: ["id", "text", "type"]
      }
    ]
  )

  return [] unless response.success?

  board = response.body.dig("data", "boards", 0)
  items = board.dig("items_page", "items") || []

  # Filter by people column
  items.select do |item|
    people_col = item["column_values"].find { |cv| cv["type"] == "people" }
    people_col && people_col["text"]&.include?(user_id.to_s)
  end
end

user_tasks = find_user_tasks(client, board_id, 12345678)
puts "User has #{user_tasks.length} assigned tasks"
```

### Task Completion Analytics

```ruby
def calculate_completion_metrics(items)
  total = items.length
  return {} if total.zero?

  # Count completed tasks
  completed = items.count do |item|
    status = item["column_values"].find { |cv| cv["id"].include?("status") }
    status&.dig("text") == "Done"
  end

  # Calculate average completion time (if you track created/completed dates)
  completion_rate = (completed.to_f / total * 100).round(1)

  # Group by priority
  high_priority = items.count do |item|
    priority = item["column_values"].select { |cv| cv["type"] == "color" }[1]
    priority&.dig("text") == "High"
  end

  {
    total: total,
    completed: completed,
    in_progress: total - completed,
    completion_rate: completion_rate,
    high_priority: high_priority,
    high_priority_percentage: (high_priority.to_f / total * 100).round(1)
  }
end

metrics = calculate_completion_metrics(all_items)
puts "Completion Rate: #{metrics[:completion_rate]}%"
puts "High Priority Tasks: #{metrics[:high_priority_percentage]}%"
```

### Bulk Status Update

```ruby
def bulk_update_status(client, board_id, item_ids, new_status)
  # Get status column ID
  board_response = client.board.query(
    args: { ids: [board_id] },
    select: [
      {
        columns: ["id", "title", "type"]
      }
    ]
  )

  return unless board_response.success?

  board = board_response.body.dig("data", "boards", 0)
  status_column = board["columns"].find { |c| c["title"] == "Status" }

  return unless status_column

  # Update each item
  item_ids.each do |item_id|
    response = client.column.change_value(
      args: {
        board_id: board_id,
        item_id: item_id,
        column_id: status_column["id"],
        value: { label: new_status }
      }
    )

    if response.success?
      puts "✓ Updated item #{item_id} to #{new_status}"
    else
      puts "✗ Failed to update item #{item_id}"
    end

    sleep(0.5)
  end
end

# Mark multiple tasks as complete
bulk_update_status(client, board_id, [123, 456, 789], "Done")
```

### Filter Tasks by Date Range

```ruby
def get_tasks_due_in_range(items, start_date, end_date)
  items.select do |item|
    date_col = item["column_values"].find { |cv| cv["type"] == "date" }
    next false unless date_col && date_col["text"]

    begin
      due_date = Date.parse(date_col["text"].split(" ").first)
      due_date >= start_date && due_date <= end_date
    rescue Date::Error
      false
    end
  end
end

# Get tasks due this week
start_of_week = Date.today
end_of_week = start_of_week + 7

this_week_tasks = get_tasks_due_in_range(
  all_items,
  start_of_week,
  end_of_week
)

puts "Tasks due this week: #{this_week_tasks.length}"
```

## Production Considerations

### 1. Environment Configuration

Use environment variables for configuration:

```ruby
# config/monday.rb
Monday.configure do |config|
  config.token = ENV.fetch("MONDAY_TOKEN")
  config.version = ENV.fetch("MONDAY_API_VERSION", "2024-10")
end
```

### 2. Logging

Add proper logging for production:

```ruby
require "logger"

class TaskManager
  attr_reader :client, :logger

  def initialize
    @client = Monday::Client.new
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  def create_task(board_id, task_data)
    logger.info("Creating task: #{task_data[:name]}")

    response = client.item.create(args: task_data)

    if response.success?
      logger.info("Task created successfully")
    else
      logger.error("Failed to create task: #{response.body}")
    end

    response
  end
end
```

### 3. Retry Logic

Handle transient failures:

```ruby
def with_retry(max_retries: 3, delay: 1)
  retries = 0

  begin
    yield
  rescue Monday::RateLimitError
    retries += 1
    if retries <= max_retries
      sleep(delay * retries)
      retry
    else
      raise
    end
  end
end

# Usage
with_retry do
  client.item.create(args: task_data)
end
```

### 4. Batch Processing

Process tasks in batches:

```ruby
def process_tasks_in_batches(tasks, batch_size: 10)
  tasks.each_slice(batch_size) do |batch|
    batch.each do |task|
      yield task
      sleep(0.5)
    end

    # Longer pause between batches
    sleep(2)
  end
end

# Usage
process_tasks_in_batches(tasks) do |task|
  client.item.create(args: task)
end
```

## Common Patterns

### Get User ID

Find your user ID for assignments:

```ruby
# Visit your Monday.com profile
# URL will be: https://monday.com/users/12345678
# The number is your user ID

# Or query via API
response = client.client.make_request(
  "query { me { id name email } }"
)

if response.success?
  user = response.body.dig("data", "me")
  puts "User ID: #{user['id']}"
  puts "Name: #{user['name']}"
  puts "Email: #{user['email']}"
end
```

### Create Task Template

Reusable task creation:

```ruby
class TaskTemplate
  def self.bug_report(board_id, title, description, priority: "High")
    {
      board_id: board_id,
      item_name: "[BUG] #{title}",
      column_values: {
        "status" => { label: "Not Started" },
        "priority" => { label: priority },
        "text" => description,
        "date4" => { date: (Date.today + 3).to_s }
      }
    }
  end

  def self.feature_request(board_id, title, description)
    {
      board_id: board_id,
      item_name: "[FEATURE] #{title}",
      column_values: {
        "status" => { label: "Planning" },
        "priority" => { label: "Medium" },
        "text" => description
      }
    }
  end
end

# Usage
bug_task = TaskTemplate.bug_report(
  board_id,
  "Login button not working",
  "Users report that clicking login does nothing"
)

client.item.create(args: bug_task)
```

## Next Steps

- [Query Items](/guides/items/query) - Learn advanced item queries
- [Update Column Values](/guides/columns/update-values) - Master column updates
- [Pagination](/guides/advanced/pagination) - Handle large datasets
- [Error Handling](/guides/advanced/errors) - Robust error handling
- [Rate Limiting](/guides/advanced/rate-limiting) - Manage API limits

## Troubleshooting

### "Column not found" errors

Get actual column IDs before setting values:

```ruby
response = client.board.query(
  args: { ids: [board_id] },
  select: [{ columns: ["id", "title", "type"] }]
)

board = response.body.dig("data", "boards", 0)
board["columns"].each do |col|
  puts "#{col['title']}: #{col['id']}"
end
```

### Rate limit errors

Add delays between requests:

```ruby
tasks.each do |task|
  client.item.create(args: task)
  sleep(0.5)  # 500ms delay
end
```

### Invalid column value format

Check column type requirements:

```ruby
# Status column
{ label: "Done" }

# Date column
{ date: "2024-12-31" }
{ date: "2024-12-31", time: "14:00:00" }

# People column
{ personsAndTeams: [{ id: 12345678, kind: "person" }] }

# Text column
"Just a string value"

# Numbers column
42  # or "42"
```

### Authentication errors

Verify your token:

```ruby
# .env
MONDAY_TOKEN=your_token_here

# In code
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

# Test authentication
response = client.board.query(args: { limit: 1 })
if response.success?
  puts "✓ Authentication successful"
else
  puts "✗ Authentication failed"
end
```
