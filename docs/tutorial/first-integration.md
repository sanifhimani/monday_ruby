# Your First monday.com Integration

Build a working monday.com integration from scratch. You'll create a project board, add tasks, and read data back.

**Time**: ~15 minutes
**Level**: Beginner

## What You'll Build

By the end of this tutorial, you'll have a Ruby script that:

- Creates a new project board on monday.com
- Adds tasks with status and priority columns
- Retrieves and displays the data
- Handles errors gracefully

This covers the fundamentals you'll use in any monday.com integration.

## Prerequisites

Before starting, make sure you have:

- **Ruby 2.7 or higher** installed
- **A monday.com account** (free trial works)
- **Basic Ruby knowledge** (variables, methods, hashes)
- **10-15 minutes** of focused time

## Step 1: Installation

Install the monday_ruby gem:

```bash
gem install monday_ruby
```

Verify the installation by checking the version:

```bash
gem list monday_ruby
```

You should see `monday_ruby` in the output with a version number.

## Step 2: Get Your API Token

Every request to monday.com requires authentication. Here's how to get your token:

1. Log in to your monday.com account
2. Click your profile picture in the top-right corner
3. Select **Administration**
4. Go to the **Connections** section
5. Select **Personal API token** in the sidebar
5. Copy your **Personal API Token**

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>Security</span>
Keep your API token secret. Never commit it to version control or share it publicly.
:::

---

### Set Up Environment Variable

Create a file called `.env` in your project directory:

```bash
# .env
MONDAY_TOKEN=your_actual_token_here
```

We'll use this to keep your token secure.

## Step 3: Create Your First Board

Let's write a script that creates a project board.

Create a new file called `monday_tutorial.rb`:

```ruby
require "monday_ruby"
require "dotenv/load"

# Configure the client with your token
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

# Initialize the client
client = Monday::Client.new

# Create a new board
response = client.board.create(
  args: {
    board_name: "My Project Tasks",
    board_kind: :public
  },
  select: ["id", "name"]
)

if response.success?
  board = response.body.dig("data", "create_board")
  puts "✓ Created board: #{board['name']} (ID: #{board['id']})"
  puts "Board ID: #{board['id']} - Save this, we'll need it!"
else
  puts "✗ Error creating board: #{response.code}"
  puts response.body
end
```

Install the dotenv gem to load environment variables:

```bash
gem install dotenv
```

Run your script:

```bash
ruby monday_tutorial.rb
```

**Expected output:**
```
✓ Created board: My Project Tasks (ID: 1234567890)
Board ID: 1234567890 - Save this, we'll need it!
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>Verify in monday.com</span>
Open monday.com in your browser. You should see your new "My Project Tasks" board!
:::

## Step 4: Add Tasks to Your Board

Now let's add some tasks to the board. We'll start simple by creating items with just names:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# Replace with your board ID from Step 3
BOARD_ID = 1234567890

# Create three tasks
tasks = ["Design database schema", "Set up development environment", "Write API documentation"]

puts "Creating tasks..."

tasks.each do |task_name|
  response = client.item.create(
    args: {
      board_id: BOARD_ID,
      item_name: task_name
    },
    select: ["id", "name"]
  )

  if response.success?
    item = response.body.dig("data", "create_item")
    puts "✓ Created: #{item['name']}"
  else
    puts "✗ Failed to create: #{task_name}"
  end
end

puts "\nAll tasks created!"
```

Run the script:

```bash
ruby monday_tutorial.rb
```

**Expected output:**
```
Creating tasks...
✓ Created: Design database schema
✓ Created: Set up development environment
✓ Created: Write API documentation

All tasks created!
```

Check your board on monday.com - you should see all three tasks!

## Step 5: Discover Column IDs

Before we can update column values, we need to discover what columns exist on the board and their IDs:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

BOARD_ID = 1234567890  # Your board ID

# Query the board to get column information
response = client.board.query(
  args: { ids: [BOARD_ID] },
  select: [
    "name",
    {
      columns: ["id", "title", "type"]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "boards", 0)

  puts "\n📋 Board: #{board['name']}"
  puts "=" * 50
  puts "\nAvailable Columns:"

  board["columns"].each do |column|
    puts "  • #{column['title']} (ID: #{column['id']}, Type: #{column['type']})"
  end

  puts "\n" + "=" * 50
else
  puts "✗ Error fetching board"
  puts response.body
end
```

Run the script:

```bash
ruby monday_tutorial.rb
```

**Expected output:**
```
📋 Board: My Project Tasks
==================================================

Available Columns:
  • Name (ID: name, Type: name)
  • Status (ID: status__1, Type: color)
  • Person (ID: person__1, Type: multiple-person)
  • Date (ID: date4__1, Type: date)

==================================================
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Column IDs</span>
Notice that column IDs have auto-generated suffixes like `__1` or random characters (e.g., `status__1`, `color_a8d9f`). The Status column type is `color`, not `status`. Always query the board first to discover the actual column IDs before updating values.
:::

## Step 6: Update Column Values

Now that we know the column IDs, let's update the status for our tasks.

**Important**: Replace `status__1` below with the actual Status column ID you saw in Step 5:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

BOARD_ID = 1234567890  # Your board ID
STATUS_COLUMN_ID = "status__1"  # Replace with your actual Status column ID from Step 5

# First, get the items
response = client.board.query(
  args: { ids: [BOARD_ID] },
  select: [
    {
      items: ["id", "name"]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "boards", 0)
  items = board["items"]

  puts "Updating task statuses...\n"

  # Update each item's status
  items.each_with_index do |item, index|
    status_labels = ["Working on it", "Done", "Stuck"]

    update_response = client.column.update_value(
      args: {
        item_id: item["id"],
        board_id: BOARD_ID,
        column_id: STATUS_COLUMN_ID,
        value: { label: status_labels[index] }
      }
    )

    if update_response.success?
      puts "✓ Updated: #{item['name']} → #{status_labels[index]}"
    else
      puts "✗ Failed to update: #{item['name']}"
    end
  end

  puts "\nAll statuses updated!"
else
  puts "✗ Error fetching items"
end
```

Run the script:

```bash
ruby monday_tutorial.rb
```

**Expected output:**
```
Updating task statuses...

✓ Updated: Design database schema → Working on it
✓ Updated: Set up development environment → Done
✓ Updated: Write API documentation → Stuck

All statuses updated!
```

Check your board on monday.com - you should now see the status labels on each task!

## Step 7: Read Data Back

Now let's query the board to see all our items with their column values:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

BOARD_ID = 1234567890  # Your board ID

# Query the board with items and column values
response = client.board.query(
  args: { ids: [BOARD_ID] },
  select: [
    "name",
    {
      items: [
        "id",
        "name",
        {
          column_values: ["id", "text", "title"]
        }
      ]
    }
  ]
)

if response.success?
  board = response.body.dig("data", "boards", 0)

  puts "\n📋 Board: #{board['name']}"
  puts "=" * 50

  board["items"].each do |item|
    puts "\n#{item['name']}"

    # Find and display the status column
    status = item["column_values"].find { |col| col["title"] == "Status" }
    if status
      puts "  Status: #{status['text']}"
    end
  end

  puts "\n" + "=" * 50
  puts "Total tasks: #{board['items'].length}"
else
  puts "✗ Error fetching board"
  puts response.body
end
```

Run the script:

```bash
ruby monday_tutorial.rb
```

**Expected output:**
```
📋 Board: My Project Tasks
==================================================

Design database schema
  Status: Working on it

Set up development environment
  Status: Done

Write API documentation
  Status: Stuck

==================================================
Total tasks: 3
```

---

## Step 8: Handle Errors

Professional integrations need error handling. Let's add it:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

BOARD_ID = 1234567890

def create_task(client, board_id, task_name, status)
  response = client.item.create(
    args: {
      board_id: board_id,
      item_name: task_name,
      column_values: {
        status: { label: status }
      }
    }
  )

  if response.success?
    item = response.body.dig("data", "create_item")
    puts "✓ Created: #{item['name']}"
    true
  else
    puts "✗ Failed to create: #{task_name}"
    puts "  Error code: #{response.code}"
    false
  end
rescue Monday::AuthorizationError
  puts "✗ Authentication failed. Check your API token."
  false
rescue Monday::Error => e
  puts "✗ monday.com API error: #{e.message}"
  false
rescue StandardError => e
  puts "✗ Unexpected error: #{e.message}"
  false
end

# Test error handling
puts "Creating task with proper error handling..."
create_task(client, BOARD_ID, "Test task", "Working on it")

# Test with invalid board ID
puts "\nTesting error handling with invalid board..."
create_task(client, 999999999, "This will fail", "Working on it")
```

Run it:

```bash
ruby monday_tutorial.rb
```

**Expected output:**
```
Creating task with proper error handling...
✓ Created: Test task

Testing error handling with invalid board...
✗ Failed to create: This will fail
  Error code: 200
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Error Types</span>
monday_ruby provides specific error classes:
- `Monday::AuthorizationError` - Invalid token
- `Monday::ResourceNotFoundError` - Board/item doesn't exist
- `Monday::RateLimitError` - Too many requests
- `Monday::Error` - General API errors
:::

## Complete Script

Here's the final, production-ready version with everything combined:

```ruby
require "monday_ruby"
require "dotenv/load"

# Configure client
Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

def create_board(client, name)
  response = client.board.create(
    args: { board_name: name, board_kind: :public },
    select: ["id", "name"]
  )

  if response.success?
    board = response.body.dig("data", "create_board")
    puts "✓ Created board: #{board['name']} (ID: #{board['id']})"
    board['id'].to_i
  else
    puts "✗ Failed to create board"
    nil
  end
rescue Monday::Error => e
  puts "✗ Error: #{e.message}"
  nil
end

def create_task(client, board_id, name)
  response = client.item.create(
    args: {
      board_id: board_id,
      item_name: name
    }
  )

  if response.success?
    item = response.body.dig("data", "create_item")
    puts "✓ Created task: #{item['name']}"
    true
  else
    puts "✗ Failed to create task: #{name}"
    false
  end
rescue Monday::Error => e
  puts "✗ Error creating task: #{e.message}"
  false
end

def update_task_status(client, board_id, item_id, column_id, status)
  response = client.column.update_value(
    args: {
      item_id: item_id,
      board_id: board_id,
      column_id: column_id,
      value: { label: status }
    }
  )

  if response.success?
    puts "✓ Updated status: #{status}"
    true
  else
    puts "✗ Failed to update status"
    false
  end
rescue Monday::Error => e
  puts "✗ Error updating status: #{e.message}"
  false
end

def display_board(client, board_id)
  response = client.board.query(
    args: { ids: [board_id] },
    select: [
      "name",
      { items: ["id", "name", { column_values: ["id", "text", "title"] }] }
    ]
  )

  if response.success?
    board = response.body.dig("data", "boards", 0)

    puts "\n📋 #{board['name']}"
    puts "=" * 50

    board["items"].each do |item|
      status = item["column_values"].find { |c| c["title"] == "Status" }
      puts "• #{item['name']} - #{status&.dig('text') || 'No status'}"
    end

    puts "=" * 50
    board["items"]
  else
    puts "✗ Failed to fetch board"
    []
  end
rescue Monday::Error => e
  puts "✗ Error: #{e.message}"
  []
end

# Main execution
puts "🚀 Building your first monday.com integration\n\n"

# Step 1: Create board
board_id = create_board(client, "My Project Tasks")
exit unless board_id

puts "\n"

# Step 2: Add tasks
tasks = ["Design database schema", "Set up development environment", "Write API documentation"]

item_ids = []
tasks.each do |task_name|
  if create_task(client, board_id, task_name)
    # Get the created item's ID
    items = display_board(client, board_id)
    item_ids = items.map { |item| item["id"] }
  end
end

puts "\n"

# Step 3: Discover the Status column ID
columns_response = client.board.query(
  args: { ids: [board_id] },
  select: [{ columns: ["id", "title", "type"] }]
)

status_column_id = nil
if columns_response.success?
  board = columns_response.body.dig("data", "boards", 0)
  status_column = board["columns"].find { |col| col["title"] == "Status" }
  status_column_id = status_column["id"] if status_column
  puts "Found Status column ID: #{status_column_id}"
end

puts "\n"

# Step 4: Update task statuses
if status_column_id
  statuses = ["Working on it", "Done", "Stuck"]
  item_ids.each_with_index do |item_id, index|
    update_task_status(client, board_id, item_id, status_column_id, statuses[index])
  end
else
  puts "⚠ Could not find Status column. Skipping status updates."
end

# Step 5: Display final results
display_board(client, board_id)

puts "\n✨ Integration complete! Check monday.com to see your board."
```

## What You've Learned

Congratulations! You've built a complete monday.com integration. Here's what you now know:

<span style="display: inline-flex; align-items: center; gap: 8px;"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>**Installing and configuring** monday_ruby</span>

<span style="display: inline-flex; align-items: center; gap: 8px;"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>**Authenticating** with the API</span>

<span style="display: inline-flex; align-items: center; gap: 8px;"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>**Creating boards** programmatically</span>

<span style="display: inline-flex; align-items: center; gap: 8px;"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>**Adding items** to boards</span>

<span style="display: inline-flex; align-items: center; gap: 8px;"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>**Discovering column IDs** dynamically</span>

<span style="display: inline-flex; align-items: center; gap: 8px;"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>**Updating column values** on items</span>

<span style="display: inline-flex; align-items: center; gap: 8px;"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>**Querying data** and parsing responses</span>

<span style="display: inline-flex; align-items: center; gap: 8px;"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>**Handling errors** gracefully</span>

## Next Steps

Now that you understand the basics, explore more:

### Learn More Operations
- [Update board settings](/guides/boards/update)
- [Work with different column types](/guides/columns/update-values)
- [Handle pagination for large datasets](/guides/advanced/pagination)

### Build Real Use Cases
- [Task management integration](/guides/use-cases/task-management)
- [Automated reporting dashboard](/guides/use-cases/dashboard)
- [Data import from CSV/JSON](/guides/use-cases/import)

### Deep Dive
- [Understand the architecture](/explanation/architecture)
- [Learn GraphQL query building](/explanation/graphql)
- [Best practices for production](/explanation/best-practices/errors)

## Get Help

Stuck? Here's how to get help:

- **Check the [how-to guides](/guides/installation)** for specific tasks
- **Browse the [API reference](/reference/client)** for detailed documentation
- **Open an issue** on [GitHub](https://github.com/sanifhimani/monday_ruby/issues)

Happy coding! 🎉
