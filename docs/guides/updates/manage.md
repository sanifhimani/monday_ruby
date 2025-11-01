# Manage Updates

Work with updates (comments) on monday.com items programmatically.

## What are Updates?

Updates are comments or posts on items in monday.com. They appear in the item's updates section and support:

- Text content
- User mentions
- Rich formatting
- Replies and threads

## Post an Update

Add a comment to an item:

```ruby
require "monday_ruby"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

response = client.update.create(
  args: {
    item_id: 123456,
    body: "This update will be added to the item"
  }
)

if response.success?
  update = response.body.dig("data", "create_update")
  puts "Update posted: #{update['body']}"
  puts "Update ID: #{update['id']}"
  puts "Posted at: #{update['created_at']}"
else
  puts "Failed to post update"
end
```

**Output:**
```
Update posted: This update will be added to the item
Update ID: 3325555116
Posted at: 2024-07-25T03:46:49Z
```

## Mention Users in Updates

Use HTML tags to mention users in your updates:

```ruby
# Mention a single user
response = client.update.create(
  args: {
    item_id: 123456,
    body: "Hey <@12345678>, can you review this task?"
  }
)
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>User ID Format</span>
Use `<@user_id>` to mention users. Replace `user_id` with the actual monday.com user ID. Mentioned users will receive a notification.
:::

### Mention Multiple Users

```ruby
response = client.update.create(
  args: {
    item_id: 123456,
    body: "Team update: <@12345678> and <@87654321> - please review by EOD"
  }
)
```

### Mention Teams

```ruby
response = client.update.create(
  args: {
    item_id: 123456,
    body: "Attention <team_id:98765>: New requirements posted"
  }
)
```

## Query Updates

Retrieve updates from items or your account:

### Get Recent Updates

```ruby
response = client.update.query(
  args: { limit: 10 },
  select: [
    "id",
    "body",
    "created_at",
    {
      creator: ["id", "name", "email"]
    }
  ]
)

if response.success?
  updates = response.body.dig("data", "updates")

  puts "Recent Updates:"
  updates.each do |update|
    creator = update["creator"]
    puts "\n#{creator['name']} (#{update['created_at']}):"
    puts "  #{update['body']}"
  end
end
```

### Get Specific Updates

```ruby
response = client.update.query(
  args: { ids: [3325555116, 3325560030] },
  select: ["id", "body", "created_at", "text_body"]
)

if response.success?
  updates = response.body.dig("data", "updates")
  updates.each do |update|
    puts "Update #{update['id']}: #{update['body']}"
  end
end
```

### Get Item Updates

To get updates for a specific item, query the item with updates nested:

```ruby
response = client.item.query(
  args: { ids: [123456] },
  select: [
    "id",
    "name",
    {
      updates: [
        "id",
        "body",
        "created_at",
        { creator: ["id", "name"] }
      ]
    }
  ]
)

if response.success?
  item = response.body.dig("data", "items", 0)
  puts "Updates on '#{item['name']}':"

  item["updates"].each do |update|
    puts "\n#{update.dig('creator', 'name')}:"
    puts "  #{update['body']}"
  end
end
```

## Like an Update

Show appreciation for an update:

```ruby
response = client.update.like(
  args: { update_id: 3325555116 }
)

if response.success?
  liked_update = response.body.dig("data", "like_update")
  puts "Liked update ID: #{liked_update['id']}"
end
```

## Delete an Update

Remove a specific update:

```ruby
response = client.update.delete(
  args: { id: 3325555116 }
)

if response.success?
  deleted = response.body.dig("data", "delete_update")
  puts "Deleted update ID: #{deleted['id']}"
else
  puts "Failed to delete update"
end
```

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Permanent Deletion</span>
Deleting an update is permanent and cannot be undone. Only the update creator or board admins can delete updates.
:::

## Clear All Updates from an Item

Remove all updates from an item at once:

```ruby
response = client.update.clear_item_updates(
  args: { item_id: 123456 }
)

if response.success?
  result = response.body.dig("data", "clear_item_updates")
  puts "Cleared all updates from item #{result['id']}"
end
```

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Destructive Operation</span>
This permanently deletes ALL updates from the item. This action cannot be undone. Use with caution.
:::

## Format Update Text

### Add Line Breaks

Use `\n` for line breaks in update text:

```ruby
update_text = <<~UPDATE
  Task Status Update:

  ✓ Completed design mockups
  ✓ Implemented core features
  ⚠ Testing in progress

  Next steps: Deploy to staging
UPDATE

response = client.update.create(
  args: {
    item_id: 123456,
    body: update_text
  }
)
```

### Add Links

Include hyperlinks in your updates:

```ruby
response = client.update.create(
  args: {
    item_id: 123456,
    body: "Check out the docs: https://developer.monday.com/api-reference"
  }
)
```

### Bold and Italic Text

Use markdown-style formatting:

```ruby
response = client.update.create(
  args: {
    item_id: 123456,
    body: "**Important:** This task is *high priority*"
  }
)
```

## Post Status Updates

Track progress with regular updates:

```ruby
def post_status_update(client, item_id, status, details)
  timestamp = Time.now.strftime("%Y-%m-%d %H:%M")

  body = <<~STATUS
    [#{timestamp}] Status: #{status}

    #{details}
  STATUS

  response = client.update.create(
    args: {
      item_id: item_id,
      body: body
    }
  )

  if response.success?
    update = response.body.dig("data", "create_update")
    puts "Posted status update: #{update['id']}"
    true
  else
    puts "Failed to post status update"
    false
  end
end

# Usage
post_status_update(
  client,
  123456,
  "In Progress",
  "Working on feature implementation. ETA: 2 hours."
)
```

## Reply to Updates

Create threaded conversations by replying to updates:

```ruby
# First, get the parent update ID
parent_update_id = 3325555116

# Post a reply (this is done by creating a new update on the same item)
response = client.update.create(
  args: {
    item_id: 123456,
    body: "Great point! I'll handle that right away."
  }
)
```

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>Replies</span>
While the API creates flat updates, the monday.com UI organizes them into threads. Updates are displayed chronologically within the item's updates section.
:::

## Bulk Create Updates

Post multiple updates efficiently:

```ruby
def post_bulk_updates(client, item_id, messages)
  posted = []

  messages.each do |message|
    response = client.update.create(
      args: {
        item_id: item_id,
        body: message
      }
    )

    if response.success?
      update = response.body.dig("data", "create_update")
      posted << update
      puts "✓ Posted: #{message[0..50]}..."
    else
      puts "✗ Failed to post: #{message[0..50]}..."
    end

    # Rate limiting: pause between requests
    sleep(0.3)
  end

  posted
end

# Usage
progress_updates = [
  "Started design phase",
  "Mockups completed and approved",
  "Development in progress",
  "First iteration deployed to staging",
  "QA testing completed"
]

posted = post_bulk_updates(client, 123456, progress_updates)
puts "\nPosted #{posted.length} updates"
```

## Error Handling

Handle common update errors gracefully:

```ruby
def create_update_safe(client, item_id, body)
  response = client.update.create(
    args: {
      item_id: item_id,
      body: body
    }
  )

  if response.success?
    update = response.body.dig("data", "create_update")
    puts "✓ Posted update: #{update['id']}"
    update['id']
  else
    puts "✗ Failed to post update"
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
  puts "✗ Invalid request: #{e.message}"
  puts "  Check that the item_id is correct"
  nil
rescue Monday::Error => e
  puts "✗ API error: #{e.message}"
  nil
end

# Usage
update_id = create_update_safe(
  client,
  123456,
  "This is a safe update with error handling"
)
```

## Validate Update Content

Check update content before posting:

```ruby
def valid_update_body?(body)
  return false if body.nil? || body.strip.empty?
  return false if body.length > 10000  # monday.com has a character limit

  true
end

update_body = "This is a valid update"

if valid_update_body?(update_body)
  response = client.update.create(
    args: {
      item_id: 123456,
      body: update_body
    }
  )
else
  puts "Invalid update content"
end
```

## Get Update Creator Information

Retrieve who posted an update:

```ruby
response = client.update.query(
  args: { ids: [3325555116] },
  select: [
    "id",
    "body",
    "created_at",
    {
      creator: [
        "id",
        "name",
        "email",
        "photo_thumb"
      ]
    }
  ]
)

if response.success?
  update = response.body.dig("data", "updates", 0)
  creator = update["creator"]

  puts "Update by: #{creator['name']}"
  puts "Email: #{creator['email']}"
  puts "Posted: #{update['created_at']}"
  puts "Content: #{update['body']}"
end
```

## Complete Example

Post a comprehensive status update with mentions and formatting:

```ruby
require "monday_ruby"
require "dotenv/load"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new

# Define item and user IDs
item_id = 123456
project_manager_id = 12345678
developer_id = 87654321

# Create formatted update with mentions
update_body = <<~UPDATE
  **Weekly Status Update**

  Progress this week:
  ✓ Completed UI redesign
  ✓ Implemented new authentication flow
  ✓ Updated documentation

  Next week priorities:
  • Deploy to production
  • User acceptance testing
  • Performance optimization

  Action items:
  <@#{project_manager_id}> - Schedule production deployment
  <@#{developer_id}> - Review performance metrics

  Questions or concerns? Let's discuss in tomorrow's standup.
UPDATE

# Post the update
response = client.update.create(
  args: {
    item_id: item_id,
    body: update_body
  },
  select: [
    "id",
    "body",
    "created_at",
    "text_body",
    {
      creator: ["id", "name"]
    }
  ]
)

if response.success?
  update = response.body.dig("data", "create_update")

  puts "\n✓ Status Update Posted Successfully\n"
  puts "=" * 50
  puts "Update ID: #{update['id']}"
  puts "Posted by: #{update.dig('creator', 'name')}"
  puts "Posted at: #{update['created_at']}"
  puts "\nContent:"
  puts update['body']
  puts "=" * 50
else
  puts "\n✗ Failed to post update"
  puts "Status code: #{response.status}"

  if response.body["error_message"]
    puts "Error: #{response.body['error_message']}"
  end
end
```

## Monitor Item Activity

Track all activity on an item:

```ruby
def monitor_item_activity(client, item_id, interval: 60)
  last_update_id = nil

  loop do
    response = client.item.query(
      args: { ids: [item_id] },
      select: [
        "id",
        "name",
        {
          updates: [
            "id",
            "body",
            "created_at",
            { creator: ["name"] }
          ]
        }
      ]
    )

    if response.success?
      item = response.body.dig("data", "items", 0)
      updates = item["updates"] || []

      # Show new updates
      updates.each do |update|
        if last_update_id.nil? || update["id"].to_i > last_update_id.to_i
          puts "\n[#{update['created_at']}] #{update.dig('creator', 'name')}:"
          puts "  #{update['body']}"
          last_update_id = update["id"].to_i
        end
      end
    end

    sleep(interval)
  end
end

# Monitor item for new updates every 60 seconds
# monitor_item_activity(client, 123456, interval: 60)
```

## Next Steps

- [Query items](/guides/items/query)
- [Create items](/guides/items/create)
- [Update item values](/guides/items/update)
- [Work with columns](/guides/columns/update-values)
