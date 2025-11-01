# Data Import Guide

Learn how to import data from various sources (CSV, JSON, databases, APIs) into monday.com using the monday_ruby gem. This guide covers data validation, error handling, progress tracking, and resume functionality for production-ready import systems.

## Overview

This guide demonstrates building robust data import systems that can:

- Import from CSV, JSON, SQL databases, and REST APIs
- Validate data before import to catch errors early
- Handle large datasets with batching and rate limiting
- Track progress and resume failed imports
- Recover from errors gracefully
- Provide detailed import reports

## Prerequisites

```ruby
# Gemfile
gem 'monday_ruby'
gem 'csv'        # Built-in, for CSV imports
gem 'json'       # Built-in, for JSON imports
gem 'sequel'     # Optional, for database imports
gem 'httparty'   # Optional, for API imports
```

Initialize the client:

```ruby
require 'monday_ruby'
require 'csv'
require 'json'

client = Monday::Client.new(token: ENV['MONDAY_API_TOKEN'])
```

## Import from CSV

### Basic CSV Import

Import a simple CSV file into a monday.com board:

```ruby
require 'monday_ruby'
require 'csv'

class CSVImporter
  def initialize(client, board_id)
    @client = client
    @board_id = board_id
  end

  def import(csv_file_path)
    results = { success: 0, failed: 0, errors: [] }

    CSV.foreach(csv_file_path, headers: true) do |row|
      begin
        create_item(row)
        results[:success] += 1
      rescue => e
        results[:failed] += 1
        results[:errors] << { row: row.to_h, error: e.message }
      end
    end

    results
  end

  private

  def create_item(row)
    # Map CSV columns to monday.com column values
    column_values = {
      "status" => { "label" => row["status"] },
      "text" => row["description"],
      "numbers" => row["amount"].to_f,
      "date" => row["due_date"]
    }

    @client.item.create(
      args: {
        board_id: @board_id,
        item_name: row["name"],
        column_values: JSON.generate(column_values)
      },
      select: ["id", "name"]
    )
  end
end

# Usage
client = Monday::Client.new(token: ENV['MONDAY_API_TOKEN'])
importer = CSVImporter.new(client, 123456789)
results = importer.import('data/tasks.csv')

puts "Imported: #{results[:success]}, Failed: #{results[:failed]}"
results[:errors].each do |error|
  puts "Error in row #{error[:row]}: #{error[:error]}"
end
```

**Example CSV file (data/tasks.csv):**

```csv
name,status,description,amount,due_date
Task 1,Working on it,First task description,100.50,2025-01-15
Task 2,Done,Second task description,250.75,2025-01-20
Task 3,Stuck,Third task description,75.00,2025-01-25
```

### Advanced CSV Import with Batching

For large CSV files, batch the imports to improve performance:

```ruby
class BatchedCSVImporter
  BATCH_SIZE = 50

  def initialize(client, board_id)
    @client = client
    @board_id = board_id
  end

  def import(csv_file_path, &progress_callback)
    total_rows = CSV.read(csv_file_path).length - 1 # Subtract header
    processed = 0
    results = { success: 0, failed: 0, errors: [] }

    batch = []

    CSV.foreach(csv_file_path, headers: true).with_index do |row, index|
      batch << row

      if batch.size >= BATCH_SIZE || index == total_rows - 1
        batch_results = import_batch(batch)
        results[:success] += batch_results[:success]
        results[:failed] += batch_results[:failed]
        results[:errors].concat(batch_results[:errors])

        processed += batch.size
        progress_callback&.call(processed, total_rows)

        batch = []
        sleep(1) # Rate limiting: 1 second between batches
      end
    end

    results
  end

  private

  def import_batch(rows)
    results = { success: 0, failed: 0, errors: [] }

    rows.each do |row|
      begin
        create_item(row)
        results[:success] += 1
      rescue => e
        results[:failed] += 1
        results[:errors] << { row: row.to_h, error: e.message }
      end
    end

    results
  end

  def create_item(row)
    column_values = {
      "status" => { "label" => row["status"] },
      "text" => row["description"],
      "numbers" => row["amount"].to_f,
      "date" => row["due_date"]
    }

    @client.item.create(
      args: {
        board_id: @board_id,
        item_name: row["name"],
        column_values: JSON.generate(column_values)
      },
      select: ["id"]
    )
  end
end

# Usage with progress tracking
client = Monday::Client.new(token: ENV['MONDAY_API_TOKEN'])
importer = BatchedCSVImporter.new(client, 123456789)

results = importer.import('data/large_dataset.csv') do |processed, total|
  percentage = (processed.to_f / total * 100).round(2)
  puts "Progress: #{processed}/#{total} (#{percentage}%)"
end

puts "\nImport complete!"
puts "Success: #{results[:success]}, Failed: #{results[:failed]}"
```

### CSV Import with Column Mapping

Allow flexible column mapping from CSV to monday.com:

```ruby
class ConfigurableCSVImporter
  def initialize(client, board_id, column_mapping)
    @client = client
    @board_id = board_id
    @column_mapping = column_mapping
  end

  def import(csv_file_path)
    results = { success: 0, failed: 0, errors: [] }

    CSV.foreach(csv_file_path, headers: true) do |row|
      begin
        create_item(row)
        results[:success] += 1
      rescue => e
        results[:failed] += 1
        results[:errors] << { row: row.to_h, error: e.message }
      end
    end

    results
  end

  private

  def create_item(row)
    # Use the item_name field from mapping
    item_name = row[@column_mapping[:item_name]]

    # Build column values based on mapping
    column_values = {}
    @column_mapping[:columns].each do |monday_column, config|
      csv_column = config[:csv_column]
      value = row[csv_column]

      next if value.nil? || value.strip.empty?

      column_values[monday_column] = format_value(value, config[:type])
    end

    @client.item.create(
      args: {
        board_id: @board_id,
        item_name: item_name,
        column_values: JSON.generate(column_values)
      },
      select: ["id"]
    )
  end

  def format_value(value, type)
    case type
    when :status
      { "label" => value }
    when :text
      value
    when :number
      value.to_f
    when :date
      value
    when :person
      { "personsAndTeams" => [{ "id" => value.to_i, "kind" => "person" }] }
    when :dropdown
      { "labels" => [value] }
    else
      value
    end
  end
end

# Define mapping configuration
mapping = {
  item_name: "Task Name",
  columns: {
    "status" => { csv_column: "Current Status", type: :status },
    "text" => { csv_column: "Notes", type: :text },
    "numbers" => { csv_column: "Budget", type: :number },
    "date" => { csv_column: "Deadline", type: :date },
    "person" => { csv_column: "Owner ID", type: :person },
    "dropdown" => { csv_column: "Priority", type: :dropdown }
  }
}

# Usage
client = Monday::Client.new(token: ENV['MONDAY_API_TOKEN'])
importer = ConfigurableCSVImporter.new(client, 123456789, mapping)
results = importer.import('data/custom_format.csv')
```

## Import from JSON

### Basic JSON Import

Import from a JSON file or API response:

```ruby
require 'monday_ruby'
require 'json'

class JSONImporter
  def initialize(client, board_id)
    @client = client
    @board_id = board_id
  end

  def import(json_file_path)
    data = JSON.parse(File.read(json_file_path))
    results = { success: 0, failed: 0, errors: [] }

    data.each do |record|
      begin
        create_item(record)
        results[:success] += 1
      rescue => e
        results[:failed] += 1
        results[:errors] << { record: record, error: e.message }
      end
    end

    results
  end

  private

  def create_item(record)
    column_values = build_column_values(record)

    @client.item.create(
      args: {
        board_id: @board_id,
        item_name: record["name"],
        column_values: JSON.generate(column_values)
      },
      select: ["id", "name"]
    )
  end

  def build_column_values(record)
    {
      "status" => { "label" => record["status"] },
      "text" => record["description"],
      "numbers" => record["amount"],
      "date" => record["due_date"]
    }
  end
end

# Usage
client = Monday::Client.new(token: ENV['MONDAY_API_TOKEN'])
importer = JSONImporter.new(client, 123456789)
results = importer.import('data/tasks.json')
```

**Example JSON file (data/tasks.json):**

```json
[
  {
    "name": "Task 1",
    "status": "Working on it",
    "description": "First task description",
    "amount": 100.50,
    "due_date": "2025-01-15"
  },
  {
    "name": "Task 2",
    "status": "Done",
    "description": "Second task description",
    "amount": 250.75,
    "due_date": "2025-01-20"
  }
]
```

### Import Nested JSON Structures

Handle complex JSON with nested objects and arrays:

```ruby
class NestedJSONImporter
  def initialize(client, board_id)
    @client = client
    @board_id = board_id
  end

  def import(json_file_path)
    data = JSON.parse(File.read(json_file_path))
    results = { success: 0, failed: 0, errors: [] }

    data.each do |record|
      begin
        # Create main item
        item_response = create_main_item(record)
        item_id = item_response.dig("data", "create_item", "id")

        # Create subitems if present
        if record["subtasks"] && !record["subtasks"].empty?
          create_subitems(item_id, record["subtasks"])
        end

        results[:success] += 1
      rescue => e
        results[:failed] += 1
        results[:errors] << { record: record, error: e.message }
      end
    end

    results
  end

  private

  def create_main_item(record)
    column_values = {
      "status" => { "label" => record["status"] },
      "text" => record["description"],
      "numbers" => record["budget"]["amount"],
      "dropdown" => { "labels" => record["tags"] }
    }

    @client.item.create(
      args: {
        board_id: @board_id,
        item_name: record["name"],
        column_values: JSON.generate(column_values)
      },
      select: ["id", "name"]
    )
  end

  def create_subitems(parent_id, subtasks)
    subtasks.each do |subtask|
      @client.item.create(
        args: {
          parent_item_id: parent_id,
          item_name: subtask["name"]
        },
        select: ["id"]
      )
    end
  end
end

# Usage
client = Monday::Client.new(token: ENV['MONDAY_API_TOKEN'])
importer = NestedJSONImporter.new(client, 123456789)
results = importer.import('data/nested_tasks.json')
```

**Example nested JSON (data/nested_tasks.json):**

```json
[
  {
    "name": "Project Alpha",
    "status": "Working on it",
    "description": "Main project",
    "budget": {
      "amount": 5000,
      "currency": "USD"
    },
    "tags": ["urgent", "client-work"],
    "subtasks": [
      {"name": "Subtask 1"},
      {"name": "Subtask 2"}
    ]
  }
]
```

## Import from Database

### SQL Database Import

Import data from a SQL database using Sequel:

```ruby
require 'monday_ruby'
require 'sequel'

class DatabaseImporter
  BATCH_SIZE = 100

  def initialize(client, board_id, db_url)
    @client = client
    @board_id = board_id
    @db = Sequel.connect(db_url)
  end

  def import(table_name, where_clause: nil, &progress_callback)
    dataset = @db[table_name.to_sym]
    dataset = dataset.where(where_clause) if where_clause

    total_rows = dataset.count
    processed = 0
    results = { success: 0, failed: 0, errors: [] }

    dataset.each_slice(BATCH_SIZE) do |batch|
      batch.each do |row|
        begin
          create_item(row)
          results[:success] += 1
        rescue => e
          results[:failed] += 1
          results[:errors] << { row: row, error: e.message }
        end

        processed += 1
        progress_callback&.call(processed, total_rows)
      end

      sleep(1) # Rate limiting
    end

    results
  ensure
    @db.disconnect
  end

  private

  def create_item(row)
    column_values = {
      "status" => { "label" => row[:status] },
      "text" => row[:description],
      "numbers" => row[:amount].to_f,
      "date" => row[:due_date]&.strftime("%Y-%m-%d")
    }

    @client.item.create(
      args: {
        board_id: @board_id,
        item_name: row[:name],
        column_values: JSON.generate(column_values)
      },
      select: ["id"]
    )
  end
end

# Usage
client = Monday::Client.new(token: ENV['MONDAY_API_TOKEN'])
db_url = "postgres://user:password@localhost/mydb"

importer = DatabaseImporter.new(client, 123456789, db_url)
results = importer.import('tasks', where_clause: { active: true }) do |processed, total|
  puts "Imported #{processed}/#{total} records"
end
```

### Database Import with Transformation

Transform database records before importing:

```ruby
class TransformingDatabaseImporter
  def initialize(client, board_id, db_url, transformer)
    @client = client
    @board_id = board_id
    @db = Sequel.connect(db_url)
    @transformer = transformer
  end

  def import(query)
    results = { success: 0, failed: 0, errors: [] }

    @db.fetch(query).each do |row|
      begin
        transformed_data = @transformer.call(row)
        create_item(transformed_data)
        results[:success] += 1
      rescue => e
        results[:failed] += 1
        results[:errors] << { row: row, error: e.message }
      end
    end

    results
  ensure
    @db.disconnect
  end

  private

  def create_item(data)
    @client.item.create(
      args: {
        board_id: @board_id,
        item_name: data[:name],
        column_values: JSON.generate(data[:columns])
      },
      select: ["id"]
    )
  end
end

# Define a transformer
transformer = lambda do |row|
  {
    name: "#{row[:first_name]} #{row[:last_name]}",
    columns: {
      "email" => row[:email],
      "text" => row[:notes],
      "status" => { "label" => row[:is_active] ? "Active" : "Inactive" },
      "date" => row[:created_at]&.strftime("%Y-%m-%d")
    }
  }
end

# Usage
client = Monday::Client.new(token: ENV['MONDAY_API_TOKEN'])
db_url = "postgres://user:password@localhost/mydb"

importer = TransformingDatabaseImporter.new(client, 123456789, db_url, transformer)
query = "SELECT * FROM users WHERE created_at > '2025-01-01'"
results = importer.import(query)
```

## Import from External API

### REST API Import

Fetch data from an external API and import to monday.com:

```ruby
require 'monday_ruby'
require 'httparty'

class APIImporter
  def initialize(client, board_id, api_base_url, api_key: nil)
    @client = client
    @board_id = board_id
    @api_base_url = api_base_url
    @api_key = api_key
  end

  def import(endpoint)
    results = { success: 0, failed: 0, errors: [] }

    data = fetch_from_api(endpoint)

    data.each do |record|
      begin
        create_item(record)
        results[:success] += 1
      rescue => e
        results[:failed] += 1
        results[:errors] << { record: record, error: e.message }
      end
    end

    results
  end

  private

  def fetch_from_api(endpoint)
    url = "#{@api_base_url}/#{endpoint}"
    headers = {}
    headers['Authorization'] = "Bearer #{@api_key}" if @api_key

    response = HTTParty.get(url, headers: headers)

    if response.success?
      JSON.parse(response.body)
    else
      raise "API request failed: #{response.code} - #{response.message}"
    end
  end

  def create_item(record)
    column_values = transform_api_data(record)

    @client.item.create(
      args: {
        board_id: @board_id,
        item_name: record["title"],
        column_values: JSON.generate(column_values)
      },
      select: ["id"]
    )
  end

  def transform_api_data(record)
    {
      "status" => { "label" => record["status"] },
      "text" => record["description"],
      "link" => { "url" => record["url"], "text" => "View Original" }
    }
  end
end

# Usage
client = Monday::Client.new(token: ENV['MONDAY_API_TOKEN'])
importer = APIImporter.new(
  client,
  123456789,
  "https://api.example.com/v1",
  api_key: ENV['EXTERNAL_API_KEY']
)

results = importer.import('tasks')
```

### API Import with Pagination

Handle paginated API responses:

```ruby
class PaginatedAPIImporter
  def initialize(client, board_id, api_base_url, api_key: nil)
    @client = client
    @board_id = board_id
    @api_base_url = api_base_url
    @api_key = api_key
  end

  def import(endpoint, page_size: 100, &progress_callback)
    results = { success: 0, failed: 0, errors: [], total_pages: 0 }
    page = 1

    loop do
      response_data = fetch_page(endpoint, page, page_size)
      break if response_data['items'].empty?

      results[:total_pages] = page

      response_data['items'].each do |record|
        begin
          create_item(record)
          results[:success] += 1
        rescue => e
          results[:failed] += 1
          results[:errors] << { record: record, error: e.message }
        end
      end

      progress_callback&.call(page, response_data['total_pages'])

      break unless response_data['has_more']
      page += 1
      sleep(1) # Rate limiting
    end

    results
  end

  private

  def fetch_page(endpoint, page, page_size)
    url = "#{@api_base_url}/#{endpoint}?page=#{page}&per_page=#{page_size}"
    headers = {}
    headers['Authorization'] = "Bearer #{@api_key}" if @api_key

    response = HTTParty.get(url, headers: headers)

    if response.success?
      JSON.parse(response.body)
    else
      raise "API request failed: #{response.code} - #{response.message}"
    end
  end

  def create_item(record)
    column_values = {
      "status" => { "label" => record["status"] },
      "text" => record["description"]
    }

    @client.item.create(
      args: {
        board_id: @board_id,
        item_name: record["title"],
        column_values: JSON.generate(column_values)
      },
      select: ["id"]
    )
  end
end

# Usage
client = Monday::Client.new(token: ENV['MONDAY_API_TOKEN'])
importer = PaginatedAPIImporter.new(
  client,
  123456789,
  "https://api.example.com/v1",
  api_key: ENV['EXTERNAL_API_KEY']
)

results = importer.import('tasks', page_size: 50) do |current_page, total_pages|
  puts "Processing page #{current_page}/#{total_pages}"
end
```

## Data Validation

### Pre-Import Validation

Validate data before importing to catch errors early:

```ruby
class ValidatingImporter
  def initialize(client, board_id, validators)
    @client = client
    @board_id = board_id
    @validators = validators
  end

  def import(data)
    validation_results = validate_all(data)

    if validation_results[:invalid].any?
      return {
        success: 0,
        failed: validation_results[:invalid].count,
        errors: validation_results[:invalid],
        skipped_due_to_validation: true
      }
    end

    import_valid_data(validation_results[:valid])
  end

  private

  def validate_all(data)
    results = { valid: [], invalid: [] }

    data.each_with_index do |record, index|
      errors = validate_record(record)

      if errors.empty?
        results[:valid] << record
      else
        results[:invalid] << {
          index: index,
          record: record,
          errors: errors
        }
      end
    end

    results
  end

  def validate_record(record)
    errors = []

    @validators.each do |field, rules|
      value = record[field]

      if rules[:required] && (value.nil? || value.to_s.strip.empty?)
        errors << "#{field} is required"
      end

      if rules[:type] && value
        case rules[:type]
        when :number
          errors << "#{field} must be a number" unless value.to_s =~ /^\d+(\.\d+)?$/
        when :date
          errors << "#{field} must be a valid date" unless valid_date?(value)
        when :email
          errors << "#{field} must be a valid email" unless value =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
        end
      end

      if rules[:max_length] && value && value.to_s.length > rules[:max_length]
        errors << "#{field} exceeds maximum length of #{rules[:max_length]}"
      end

      if rules[:allowed_values] && value && !rules[:allowed_values].include?(value)
        errors << "#{field} must be one of: #{rules[:allowed_values].join(', ')}"
      end
    end

    errors
  end

  def valid_date?(date_string)
    Date.parse(date_string.to_s)
    true
  rescue ArgumentError
    false
  end

  def import_valid_data(valid_records)
    results = { success: 0, failed: 0, errors: [] }

    valid_records.each do |record|
      begin
        create_item(record)
        results[:success] += 1
      rescue => e
        results[:failed] += 1
        results[:errors] << { record: record, error: e.message }
      end
    end

    results
  end

  def create_item(record)
    column_values = {
      "status" => { "label" => record["status"] },
      "text" => record["description"],
      "numbers" => record["amount"].to_f,
      "date" => record["due_date"]
    }

    @client.item.create(
      args: {
        board_id: @board_id,
        item_name: record["name"],
        column_values: JSON.generate(column_values)
      },
      select: ["id"]
    )
  end
end

# Define validation rules
validators = {
  "name" => {
    required: true,
    max_length: 255
  },
  "status" => {
    required: true,
    allowed_values: ["Working on it", "Done", "Stuck", "Not Started"]
  },
  "amount" => {
    type: :number
  },
  "due_date" => {
    type: :date
  }
}

# Usage
client = Monday::Client.new(token: ENV['MONDAY_API_TOKEN'])
importer = ValidatingImporter.new(client, 123456789, validators)

data = JSON.parse(File.read('data/tasks.json'))
results = importer.import(data)

if results[:skipped_due_to_validation]
  puts "Validation failed. Errors:"
  results[:errors].each do |error|
    puts "Record #{error[:index]}: #{error[:errors].join(', ')}"
  end
else
  puts "Import complete: #{results[:success]} success, #{results[:failed]} failed"
end
```

### Validation with Auto-Correction

Automatically fix common data issues:

```ruby
class AutoCorrectingImporter
  def initialize(client, board_id)
    @client = client
    @board_id = board_id
  end

  def import(data)
    results = { success: 0, failed: 0, corrected: 0, errors: [] }

    data.each do |record|
      begin
        corrected_record = auto_correct(record)
        results[:corrected] += 1 if corrected_record[:was_corrected]

        create_item(corrected_record[:data])
        results[:success] += 1
      rescue => e
        results[:failed] += 1
        results[:errors] << { record: record, error: e.message }
      end
    end

    results
  end

  private

  def auto_correct(record)
    was_corrected = false
    corrected = record.dup

    # Trim whitespace from all string values
    corrected.transform_values! do |value|
      if value.is_a?(String)
        trimmed = value.strip
        was_corrected = true if trimmed != value
        trimmed
      else
        value
      end
    end

    # Normalize status values
    if corrected["status"]
      normalized_status = normalize_status(corrected["status"])
      if normalized_status != corrected["status"]
        corrected["status"] = normalized_status
        was_corrected = true
      end
    end

    # Convert amount to proper format
    if corrected["amount"] && corrected["amount"].is_a?(String)
      # Remove currency symbols and commas
      cleaned_amount = corrected["amount"].gsub(/[$,]/, '')
      corrected["amount"] = cleaned_amount.to_f
      was_corrected = true
    end

    # Normalize date format
    if corrected["due_date"] && corrected["due_date"] =~ %r{^(\d{1,2})/(\d{1,2})/(\d{4})$}
      # Convert MM/DD/YYYY to YYYY-MM-DD
      month, day, year = $1, $2, $3
      corrected["due_date"] = "#{year}-#{month.rjust(2, '0')}-#{day.rjust(2, '0')}"
      was_corrected = true
    end

    { data: corrected, was_corrected: was_corrected }
  end

  def normalize_status(status)
    status_map = {
      "in progress" => "Working on it",
      "working" => "Working on it",
      "complete" => "Done",
      "completed" => "Done",
      "finished" => "Done",
      "blocked" => "Stuck",
      "waiting" => "Stuck"
    }

    status_map[status.downcase] || status
  end

  def create_item(record)
    column_values = {
      "status" => { "label" => record["status"] },
      "text" => record["description"],
      "numbers" => record["amount"],
      "date" => record["due_date"]
    }

    @client.item.create(
      args: {
        board_id: @board_id,
        item_name: record["name"],
        column_values: JSON.generate(column_values)
      },
      select: ["id"]
    )
  end
end

# Usage
client = Monday::Client.new(token: ENV['MONDAY_API_TOKEN'])
importer = AutoCorrectingImporter.new(client, 123456789)

data = JSON.parse(File.read('data/messy_tasks.json'))
results = importer.import(data)

puts "Imported: #{results[:success]}, Corrected: #{results[:corrected]}, Failed: #{results[:failed]}"
```

## Error Handling and Recovery

### Checkpoint-Based Import

Save progress and resume from last checkpoint on failure:

```ruby
require 'json'

class CheckpointImporter
  def initialize(client, board_id, checkpoint_file)
    @client = client
    @board_id = board_id
    @checkpoint_file = checkpoint_file
  end

  def import(data)
    checkpoint = load_checkpoint
    start_index = checkpoint[:last_successful_index] + 1

    puts "Resuming from index #{start_index} (#{checkpoint[:success]} already imported)"

    results = {
      success: checkpoint[:success],
      failed: checkpoint[:failed],
      errors: checkpoint[:errors]
    }

    data[start_index..-1].each_with_index do |record, offset|
      current_index = start_index + offset

      begin
        create_item(record)
        results[:success] += 1
        save_checkpoint(current_index, results)
      rescue => e
        results[:failed] += 1
        results[:errors] << {
          index: current_index,
          record: record,
          error: e.message
        }
        save_checkpoint(current_index, results)
      end
    end

    # Clear checkpoint on successful completion
    File.delete(@checkpoint_file) if File.exist?(@checkpoint_file)

    results
  end

  def reset_checkpoint
    File.delete(@checkpoint_file) if File.exist?(@checkpoint_file)
    puts "Checkpoint cleared"
  end

  private

  def load_checkpoint
    if File.exist?(@checkpoint_file)
      JSON.parse(File.read(@checkpoint_file), symbolize_names: true)
    else
      {
        last_successful_index: -1,
        success: 0,
        failed: 0,
        errors: []
      }
    end
  end

  def save_checkpoint(index, results)
    checkpoint = {
      last_successful_index: index,
      success: results[:success],
      failed: results[:failed],
      errors: results[:errors],
      updated_at: Time.now.iso8601
    }

    File.write(@checkpoint_file, JSON.pretty_generate(checkpoint))
  end

  def create_item(record)
    column_values = {
      "status" => { "label" => record["status"] },
      "text" => record["description"]
    }

    @client.item.create(
      args: {
        board_id: @board_id,
        item_name: record["name"],
        column_values: JSON.generate(column_values)
      },
      select: ["id"]
    )
  end
end

# Usage
client = Monday::Client.new(token: ENV['MONDAY_API_TOKEN'])
importer = CheckpointImporter.new(client, 123456789, 'import_checkpoint.json')

data = JSON.parse(File.read('data/large_dataset.json'))

# First run (might fail midway)
begin
  results = importer.import(data)
  puts "Complete: #{results[:success]} success, #{results[:failed]} failed"
rescue Interrupt
  puts "\nImport interrupted. Run again to resume from checkpoint."
end

# Resume from checkpoint
results = importer.import(data)
puts "Complete: #{results[:success]} success, #{results[:failed]} failed"

# Reset checkpoint if you want to start fresh
# importer.reset_checkpoint
```

### Retry with Exponential Backoff

Retry failed items with exponential backoff:

```ruby
class RetryingImporter
  MAX_RETRIES = 3
  INITIAL_RETRY_DELAY = 2 # seconds

  def initialize(client, board_id)
    @client = client
    @board_id = board_id
  end

  def import(data)
    results = { success: 0, failed: 0, errors: [] }

    data.each do |record|
      success = import_with_retry(record, results)
      results[:success] += 1 if success
    end

    results
  end

  private

  def import_with_retry(record, results)
    retries = 0

    begin
      create_item(record)
      true
    rescue => e
      retries += 1

      if retries <= MAX_RETRIES
        delay = INITIAL_RETRY_DELAY * (2 ** (retries - 1))
        puts "Error importing '#{record["name"]}': #{e.message}. Retrying in #{delay}s... (#{retries}/#{MAX_RETRIES})"
        sleep(delay)
        retry
      else
        results[:failed] += 1
        results[:errors] << {
          record: record,
          error: e.message,
          retries: retries
        }
        false
      end
    end
  end

  def create_item(record)
    column_values = {
      "status" => { "label" => record["status"] },
      "text" => record["description"]
    }

    @client.item.create(
      args: {
        board_id: @board_id,
        item_name: record["name"],
        column_values: JSON.generate(column_values)
      },
      select: ["id"]
    )
  end
end

# Usage
client = Monday::Client.new(token: ENV['MONDAY_API_TOKEN'])
importer = RetryingImporter.new(client, 123456789)

data = JSON.parse(File.read('data/tasks.json'))
results = importer.import(data)
```

### Transaction-Like Rollback

Track created items and delete them if import fails:

```ruby
class TransactionalImporter
  def initialize(client, board_id)
    @client = client
    @board_id = board_id
  end

  def import(data, rollback_on_failure: true)
    created_items = []
    results = { success: 0, failed: 0, errors: [], rolled_back: false }

    begin
      data.each do |record|
        item_id = create_item(record)
        created_items << item_id
        results[:success] += 1
      end
    rescue => e
      results[:failed] += 1
      results[:errors] << { error: e.message }

      if rollback_on_failure
        rollback(created_items)
        results[:rolled_back] = true
        results[:success] = 0
      end
    end

    results
  end

  private

  def create_item(record)
    column_values = {
      "status" => { "label" => record["status"] },
      "text" => record["description"]
    }

    response = @client.item.create(
      args: {
        board_id: @board_id,
        item_name: record["name"],
        column_values: JSON.generate(column_values)
      },
      select: ["id"]
    )

    response.dig("data", "create_item", "id")
  end

  def rollback(item_ids)
    puts "Rolling back #{item_ids.count} items..."

    item_ids.each do |item_id|
      begin
        @client.item.delete(args: { item_id: item_id })
      rescue => e
        puts "Warning: Failed to delete item #{item_id}: #{e.message}"
      end
    end

    puts "Rollback complete"
  end
end

# Usage
client = Monday::Client.new(token: ENV['MONDAY_API_TOKEN'])
importer = TransactionalImporter.new(client, 123456789)

data = JSON.parse(File.read('data/tasks.json'))
results = importer.import(data, rollback_on_failure: true)

if results[:rolled_back]
  puts "Import failed and was rolled back"
else
  puts "Import complete: #{results[:success]} items created"
end
```

## Complete Import Tool

### Full-Featured CLI Import Script

A production-ready import tool with all features combined:

```ruby
#!/usr/bin/env ruby

require 'monday_ruby'
require 'csv'
require 'json'
require 'optparse'

class DataImportTool
  SUPPORTED_FORMATS = ['csv', 'json']
  BATCH_SIZE = 50

  def initialize(client, options)
    @client = client
    @board_id = options[:board_id]
    @source_file = options[:source_file]
    @format = options[:format]
    @dry_run = options[:dry_run]
    @checkpoint_file = options[:checkpoint_file]
    @column_mapping = options[:column_mapping]
    @validate = options[:validate]
  end

  def run
    puts "=" * 60
    puts "Data Import Tool"
    puts "=" * 60
    puts "Board ID: #{@board_id}"
    puts "Source: #{@source_file}"
    puts "Format: #{@format}"
    puts "Dry run: #{@dry_run ? 'Yes' : 'No'}"
    puts "Validation: #{@validate ? 'Enabled' : 'Disabled'}"
    puts "=" * 60
    puts

    # Load data
    data = load_data
    puts "Loaded #{data.count} records"

    # Validate
    if @validate
      validation_results = validate_data(data)

      if validation_results[:invalid].any?
        puts "\nValidation failed for #{validation_results[:invalid].count} records:"
        validation_results[:invalid].first(5).each do |error|
          puts "  - Record #{error[:index]}: #{error[:errors].join(', ')}"
        end
        puts "  ... and #{validation_results[:invalid].count - 5} more" if validation_results[:invalid].count > 5

        print "\nContinue with valid records only? (y/n): "
        return unless gets.chomp.downcase == 'y'

        data = validation_results[:valid]
        puts "Proceeding with #{data.count} valid records"
      else
        puts "All records passed validation"
      end
    end

    # Dry run preview
    if @dry_run
      preview_import(data)
      return
    end

    # Actual import
    results = import_data(data)
    print_results(results)
  end

  private

  def load_data
    case @format
    when 'csv'
      load_csv
    when 'json'
      load_json
    else
      raise "Unsupported format: #{@format}"
    end
  end

  def load_csv
    data = []
    CSV.foreach(@source_file, headers: true) do |row|
      data << row.to_h
    end
    data
  end

  def load_json
    JSON.parse(File.read(@source_file))
  end

  def validate_data(data)
    validators = {
      "name" => { required: true, max_length: 255 },
      "status" => { allowed_values: ["Working on it", "Done", "Stuck", "Not Started"] }
    }

    results = { valid: [], invalid: [] }

    data.each_with_index do |record, index|
      errors = []

      validators.each do |field, rules|
        value = record[field]

        if rules[:required] && (value.nil? || value.to_s.strip.empty?)
          errors << "#{field} is required"
        end

        if rules[:max_length] && value && value.to_s.length > rules[:max_length]
          errors << "#{field} exceeds maximum length"
        end

        if rules[:allowed_values] && value && !rules[:allowed_values].include?(value)
          errors << "#{field} has invalid value"
        end
      end

      if errors.empty?
        results[:valid] << record
      else
        results[:invalid] << { index: index, record: record, errors: errors }
      end
    end

    results
  end

  def preview_import(data)
    puts "\n" + "=" * 60
    puts "DRY RUN - Preview of first 5 records:"
    puts "=" * 60

    data.first(5).each_with_index do |record, index|
      puts "\nRecord #{index + 1}:"
      puts "  Name: #{record['name']}"
      puts "  Status: #{record['status']}"
      puts "  Description: #{record['description']}"
      puts "  Amount: #{record['amount']}"
      puts "  Due Date: #{record['due_date']}"
    end

    puts "\n... and #{data.count - 5} more records" if data.count > 5
    puts "\nNo items were created (dry run mode)"
  end

  def import_data(data)
    checkpoint = load_checkpoint
    start_index = checkpoint[:last_successful_index] + 1

    if start_index > 0
      puts "Resuming from checkpoint (#{checkpoint[:success]} already imported)"
    end

    results = {
      success: checkpoint[:success],
      failed: checkpoint[:failed],
      errors: checkpoint[:errors]
    }

    total = data.count

    data[start_index..-1].each_with_index do |record, offset|
      current_index = start_index + offset

      begin
        create_item(record)
        results[:success] += 1
        save_checkpoint(current_index, results)

        # Progress update
        if (current_index + 1) % 10 == 0 || current_index == total - 1
          percentage = ((current_index + 1).to_f / total * 100).round(2)
          puts "Progress: #{current_index + 1}/#{total} (#{percentage}%)"
        end

        # Rate limiting
        sleep(0.5) if (current_index + 1) % BATCH_SIZE == 0
      rescue => e
        results[:failed] += 1
        results[:errors] << {
          index: current_index,
          record: record,
          error: e.message
        }
        save_checkpoint(current_index, results)

        puts "Error on record #{current_index + 1}: #{e.message}"
      end
    end

    # Clear checkpoint on completion
    File.delete(@checkpoint_file) if File.exist?(@checkpoint_file)

    results
  end

  def create_item(record)
    # Apply column mapping if provided
    mapped_record = @column_mapping ? apply_mapping(record) : record

    column_values = {
      "status" => { "label" => mapped_record["status"] },
      "text" => mapped_record["description"],
      "numbers" => mapped_record["amount"]&.to_f,
      "date" => mapped_record["due_date"]
    }

    # Remove nil values
    column_values.reject! { |_, v| v.nil? }

    @client.item.create(
      args: {
        board_id: @board_id,
        item_name: mapped_record["name"],
        column_values: JSON.generate(column_values)
      },
      select: ["id"]
    )
  end

  def apply_mapping(record)
    mapped = {}
    @column_mapping.each do |target, source|
      mapped[target] = record[source]
    end
    mapped
  end

  def load_checkpoint
    if @checkpoint_file && File.exist?(@checkpoint_file)
      JSON.parse(File.read(@checkpoint_file), symbolize_names: true)
    else
      { last_successful_index: -1, success: 0, failed: 0, errors: [] }
    end
  end

  def save_checkpoint(index, results)
    return unless @checkpoint_file

    checkpoint = {
      last_successful_index: index,
      success: results[:success],
      failed: results[:failed],
      errors: results[:errors],
      updated_at: Time.now.iso8601
    }

    File.write(@checkpoint_file, JSON.pretty_generate(checkpoint))
  end

  def print_results(results)
    puts "\n" + "=" * 60
    puts "Import Complete"
    puts "=" * 60
    puts "Successfully imported: #{results[:success]}"
    puts "Failed: #{results[:failed]}"

    if results[:errors].any?
      puts "\nErrors:"
      results[:errors].first(10).each do |error|
        puts "  - Record #{error[:index]}: #{error[:error]}"
      end
      puts "  ... and #{results[:errors].count - 10} more errors" if results[:errors].count > 10

      # Save error report
      error_file = "import_errors_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json"
      File.write(error_file, JSON.pretty_generate(results[:errors]))
      puts "\nFull error report saved to: #{error_file}"
    end

    puts "=" * 60
  end
end

# CLI Interface
options = {
  checkpoint_file: 'import_checkpoint.json',
  validate: true
}

OptionParser.new do |opts|
  opts.banner = "Usage: import_tool.rb [options]"

  opts.on("-b", "--board-id ID", Integer, "Monday.com board ID (required)") do |v|
    options[:board_id] = v
  end

  opts.on("-f", "--file PATH", "Path to source file (required)") do |v|
    options[:source_file] = v
  end

  opts.on("-t", "--format FORMAT", DataImportTool::SUPPORTED_FORMATS, "File format: #{DataImportTool::SUPPORTED_FORMATS.join(', ')} (required)") do |v|
    options[:format] = v
  end

  opts.on("-d", "--dry-run", "Preview import without creating items") do
    options[:dry_run] = true
  end

  opts.on("-c", "--checkpoint FILE", "Checkpoint file path (default: import_checkpoint.json)") do |v|
    options[:checkpoint_file] = v
  end

  opts.on("--no-validate", "Skip data validation") do
    options[:validate] = false
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

# Validate required options
required = [:board_id, :source_file, :format]
missing = required.select { |opt| options[opt].nil? }

if missing.any?
  puts "Error: Missing required options: #{missing.join(', ')}"
  puts "Run with --help for usage information"
  exit 1
end

# Validate file exists
unless File.exist?(options[:source_file])
  puts "Error: File not found: #{options[:source_file]}"
  exit 1
end

# Run import
begin
  client = Monday::Client.new(token: ENV['MONDAY_API_TOKEN'])
  tool = DataImportTool.new(client, options)
  tool.run
rescue => e
  puts "Fatal error: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end
```

**Usage examples:**

```bash
# Dry run to preview import
ruby import_tool.rb \
  --board-id 123456789 \
  --file data/tasks.csv \
  --format csv \
  --dry-run

# Actual import with validation
ruby import_tool.rb \
  --board-id 123456789 \
  --file data/tasks.json \
  --format json

# Import without validation (faster)
ruby import_tool.rb \
  --board-id 123456789 \
  --file data/large_dataset.csv \
  --format csv \
  --no-validate

# Resume from checkpoint after interruption
ruby import_tool.rb \
  --board-id 123456789 \
  --file data/tasks.csv \
  --format csv \
  --checkpoint my_checkpoint.json
```

## Best Practices

### 1. Always Use Batching for Large Imports

Process records in batches to avoid memory issues and respect rate limits:

```ruby
# Bad: Load everything into memory
all_items = CSV.read('huge_file.csv')
all_items.each { |item| create_item(item) }

# Good: Process in batches
CSV.foreach('huge_file.csv', headers: true).each_slice(50) do |batch|
  batch.each { |item| create_item(item) }
  sleep(1) # Rate limiting
end
```

### 2. Implement Progress Tracking

For long-running imports, provide progress feedback:

```ruby
total = data.count
data.each_with_index do |record, index|
  create_item(record)

  if (index + 1) % 10 == 0
    percentage = ((index + 1).to_f / total * 100).round(2)
    puts "Progress: #{index + 1}/#{total} (#{percentage}%)"
  end
end
```

### 3. Validate Before Importing

Catch data issues before making API calls:

```ruby
# Validate all records first
invalid = data.select { |r| r['name'].nil? || r['name'].strip.empty? }

if invalid.any?
  puts "Found #{invalid.count} invalid records"
  return
end

# Then import
data.each { |record| create_item(record) }
```

### 4. Use Checkpoints for Resumability

Save progress regularly so imports can resume after failures:

```ruby
data.each_with_index do |record, index|
  create_item(record)
  save_checkpoint(index) if index % 10 == 0
end
```

### 5. Handle Rate Limits

Add delays between batches to avoid hitting API rate limits:

```ruby
data.each_slice(50).with_index do |batch, batch_index|
  batch.each { |record| create_item(record) }
  sleep(1) if batch_index > 0 # Wait between batches
end
```

### 6. Log Errors Without Stopping

Continue processing even when individual items fail:

```ruby
errors = []

data.each do |record|
  begin
    create_item(record)
  rescue => e
    errors << { record: record, error: e.message }
    # Continue with next record
  end
end

# Report errors at the end
File.write('errors.json', JSON.pretty_generate(errors)) if errors.any?
```

### 7. Use Dry Run Mode for Testing

Always test imports with a dry run first:

```ruby
def import(data, dry_run: false)
  data.each do |record|
    if dry_run
      puts "Would create: #{record['name']}"
    else
      create_item(record)
    end
  end
end

# Test first
import(data, dry_run: true)

# Then run for real
import(data)
```

## Troubleshooting

### Import is Too Slow

**Problem:** Import takes too long for large datasets.

**Solutions:**

1. Increase batch size (but watch rate limits)
2. Reduce the `select` fields to minimum required
3. Remove unnecessary sleeps between items
4. Consider parallel processing for independent items

```ruby
# Optimize by selecting only ID
@client.item.create(
  args: { board_id: @board_id, item_name: name },
  select: ["id"] # Don't request unnecessary fields
)
```

### Rate Limit Errors

**Problem:** Getting rate limit errors from monday.com API.

**Solutions:**

1. Add delays between batches
2. Reduce batch size
3. Implement exponential backoff on rate limit errors

```ruby
begin
  create_item(record)
rescue Monday::RateLimitError => e
  wait_time = e.retry_after || 60
  puts "Rate limited. Waiting #{wait_time} seconds..."
  sleep(wait_time)
  retry
end
```

### Invalid Column Values

**Problem:** Items created but column values not set.

**Solutions:**

1. Verify column IDs match your board
2. Check column value format matches column type
3. Ensure values are JSON-encoded properly

```ruby
# Check board structure first
response = @client.board.query(
  args: { ids: [@board_id] },
  select: ["columns { id title type }"]
)

columns = response.dig("data", "boards", 0, "columns")
puts "Available columns:"
columns.each do |col|
  puts "  #{col['id']} (#{col['type']}): #{col['title']}"
end
```

### Memory Issues with Large Files

**Problem:** Running out of memory with large CSV/JSON files.

**Solutions:**

1. Use streaming parsers (`CSV.foreach` instead of `CSV.read`)
2. Process in batches
3. Don't store all results in memory

```ruby
# Bad: Loads entire file into memory
data = JSON.parse(File.read('huge_file.json'))

# Good: Stream processing
File.open('huge_file.json') do |file|
  JSON.load(file).each_slice(100) do |batch|
    batch.each { |record| create_item(record) }
  end
end
```

## Next Steps

- Read [Error Handling Guide](/guides/advanced/errors) for robust applications
- Check [Performance Optimization](/explanation/best-practices/performance) for scaling imports
- Learn about [Rate Limiting Strategy](/explanation/best-practices/rate-limiting) for large imports
- Explore [Batch Operations](/guides/advanced/batch) for bulk data processing

## Related Resources

- [monday.com API Rate Limits](https://developer.monday.com/api-reference/docs/rate-limits)
- [Column Values Reference](https://developer.monday.com/api-reference/docs/column-values)
- [Items API Documentation](https://developer.monday.com/api-reference/docs/items)
