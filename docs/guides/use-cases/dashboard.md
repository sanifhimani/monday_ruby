# Project Dashboard System

Build a comprehensive project dashboard that aggregates data from multiple boards, calculates health metrics, generates reports, and prepares visualization-ready data.

## What You'll Build

A complete project dashboard system that:
- Aggregates data from multiple project boards
- Calculates project health metrics (completion rates, overdue items, team workload)
- Tracks milestones and timeline performance
- Generates exportable reports (JSON/CSV)
- Provides real-time KPI data for dashboards

## Prerequisites

```ruby
require "monday_ruby"
require "json"
require "csv"
require "date"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

client = Monday::Client.new
```

## Step 1: Query Workspace and Identify Project Boards

First, discover all boards in your workspace and identify which ones are project boards.

### Get All Workspace Boards

```ruby
def get_workspace_boards(client, workspace_id)
  response = client.board.query(
    args: { workspace_ids: [workspace_id] },
    select: [
      "id",
      "name",
      "description",
      "state",
      {
        groups: ["id", "title"],
        columns: ["id", "title", "type"]
      }
    ]
  )

  if response.success?
    boards = response.body.dig("data", "boards") || []
    puts "Found #{boards.length} boards in workspace #{workspace_id}"
    boards
  else
    puts "Failed to fetch boards"
    []
  end
end

# Usage
workspace_id = 1234567
boards = get_workspace_boards(client, workspace_id)

boards.each do |board|
  puts "  #{board['name']} - #{board['groups'].length} groups, #{board['columns'].length} columns"
end
```

### Filter Project Boards

Identify boards that represent projects based on naming conventions or board structure:

```ruby
def identify_project_boards(boards)
  project_boards = boards.select do |board|
    # Filter by name pattern (e.g., boards with "Project" in the name)
    # or by having specific columns (status, timeline, person, etc.)
    has_project_columns = board["columns"].any? { |col| col["type"] == "status" } &&
                         board["columns"].any? { |col| col["type"] == "timeline" }

    has_project_columns || board["name"].match?(/project/i)
  end

  puts "\nIdentified #{project_boards.length} project boards:"
  project_boards.each do |board|
    puts "  • #{board['name']}"
  end

  project_boards
end

# Usage
project_boards = identify_project_boards(boards)
```

## Step 2: Aggregate Data from Multiple Boards

Collect all items from project boards using pagination for large datasets.

### Fetch All Items with Pagination

```ruby
def fetch_all_board_items(client, board_id)
  all_items = []
  cursor = nil
  page_count = 0

  loop do
    page_count += 1

    response = client.board.items_page(
      board_ids: board_id,
      limit: 100,
      cursor: cursor,
      select: [
        "id",
        "name",
        "state",
        "created_at",
        "updated_at",
        {
          group: ["id", "title"],
          column_values: [
            "id",
            "text",
            "type",
            "value",
            {
              "... on StatusValue": ["label"],
              "... on DateValue": ["date"],
              "... on PeopleValue": ["persons_and_teams"],
              "... on TimelineValue": ["from", "to"]
            }
          ]
        }
      ]
    )

    break unless response.success?

    items_page = response.body.dig("data", "boards", 0, "items_page")
    items = items_page["items"] || []

    break if items.empty?

    all_items.concat(items)
    cursor = items_page["cursor"]

    puts "  Page #{page_count}: Fetched #{items.length} items (Total: #{all_items.length})"

    break if cursor.nil?
  end

  all_items
end

# Usage
def aggregate_project_data(client, project_boards)
  project_data = {}

  project_boards.each do |board|
    puts "\nFetching items from: #{board['name']}"
    items = fetch_all_board_items(client, board["id"])

    project_data[board["id"]] = {
      "board" => board,
      "items" => items,
      "total_items" => items.length
    }
  end

  project_data
end

# Collect all data
project_data = aggregate_project_data(client, project_boards)
puts "\n✓ Aggregated data from #{project_data.keys.length} boards"
```

### Group Data by Project

```ruby
def group_items_by_status(items)
  grouped = Hash.new { |h, k| h[k] = [] }

  items.each do |item|
    status_column = item["column_values"].find { |cv| cv["type"] == "status" }
    status = status_column&.dig("text") || "No Status"
    grouped[status] << item
  end

  grouped
end

# Usage
project_data.each do |board_id, data|
  board_name = data["board"]["name"]
  grouped = group_items_by_status(data["items"])

  puts "\n#{board_name}:"
  grouped.each do |status, items|
    puts "  #{status}: #{items.length} items"
  end
end
```

## Step 3: Calculate Project Health Metrics

Calculate key metrics to assess project health and performance.

### Calculate Completion Percentage

```ruby
def calculate_completion_rate(items)
  return 0 if items.empty?

  completed_states = ["done", "completed"]
  completed_count = items.count do |item|
    status_column = item["column_values"].find { |cv| cv["type"] == "status" }
    status_text = status_column&.dig("text")&.downcase || ""
    completed_states.any? { |state| status_text.include?(state) }
  end

  (completed_count.to_f / items.length * 100).round(2)
end

# Usage
project_data.each do |board_id, data|
  completion_rate = calculate_completion_rate(data["items"])
  puts "#{data['board']['name']}: #{completion_rate}% complete"
end
```

### Count Overdue Items

```ruby
def count_overdue_items(items)
  today = Date.today
  overdue_items = []

  items.each do |item|
    # Check date columns
    date_column = item["column_values"].find { |cv| cv["type"] == "date" }
    if date_column && date_column["text"]
      begin
        due_date = Date.parse(date_column["text"])
        if due_date < today
          status_column = item["column_values"].find { |cv| cv["type"] == "status" }
          status = status_column&.dig("text")&.downcase || ""

          # Only count as overdue if not completed
          unless status.include?("done") || status.include?("completed")
            overdue_items << {
              "item" => item,
              "due_date" => due_date,
              "days_overdue" => (today - due_date).to_i
            }
          end
        end
      rescue Date::Error
        # Invalid date format, skip
      end
    end

    # Check timeline columns
    timeline_column = item["column_values"].find { |cv| cv["type"] == "timeline" }
    if timeline_column
      begin
        value = JSON.parse(timeline_column["value"] || "{}")
        if value["to"]
          end_date = Date.parse(value["to"])
          if end_date < today
            status_column = item["column_values"].find { |cv| cv["type"] == "status" }
            status = status_column&.dig("text")&.downcase || ""

            unless status.include?("done") || status.include?("completed")
              overdue_items << {
                "item" => item,
                "due_date" => end_date,
                "days_overdue" => (today - end_date).to_i
              }
            end
          end
        end
      rescue JSON::ParserError, Date::Error
        # Invalid format, skip
      end
    end
  end

  overdue_items.uniq { |oi| oi["item"]["id"] }
end

# Usage
project_data.each do |board_id, data|
  overdue = count_overdue_items(data["items"])
  puts "#{data['board']['name']}: #{overdue.length} overdue items"

  if overdue.any?
    puts "  Most overdue:"
    overdue.sort_by { |oi| -oi["days_overdue"] }.first(3).each do |oi|
      puts "    • #{oi['item']['name']} (#{oi['days_overdue']} days)"
    end
  end
end
```

### Calculate Team Workload Distribution

```ruby
def calculate_team_workload(items)
  workload = Hash.new { |h, k| h[k] = { total: 0, active: 0, completed: 0 } }

  items.each do |item|
    # Find person column
    person_column = item["column_values"].find { |cv| cv["type"] == "people" }
    next unless person_column

    begin
      value = JSON.parse(person_column["value"] || "{}")
      persons = value["personsAndTeams"] || []

      persons.each do |person|
        person_id = person["id"]
        person_name = person_column["text"] || "Unassigned"

        # Determine status
        status_column = item["column_values"].find { |cv| cv["type"] == "status" }
        status = status_column&.dig("text")&.downcase || ""

        workload[person_name][:total] += 1

        if status.include?("done") || status.include?("completed")
          workload[person_name][:completed] += 1
        else
          workload[person_name][:active] += 1
        end
      end
    rescue JSON::ParserError
      # Invalid format, skip
    end
  end

  workload
end

# Usage
project_data.each do |board_id, data|
  workload = calculate_team_workload(data["items"])

  puts "\n#{data['board']['name']} - Team Workload:"
  workload.sort_by { |name, stats| -stats[:total] }.each do |name, stats|
    completion_rate = stats[:total] > 0 ? (stats[:completed].to_f / stats[:total] * 100).round(1) : 0
    puts "  #{name}:"
    puts "    Total: #{stats[:total]} | Active: #{stats[:active]} | Completed: #{stats[:completed]} (#{completion_rate}%)"
  end
end
```

### Analyze Timeline Performance

```ruby
def analyze_timeline_performance(items)
  today = Date.today
  timeline_stats = {
    on_time: 0,
    at_risk: 0,    # Due within 7 days
    delayed: 0,
    completed_on_time: 0,
    completed_late: 0,
    no_timeline: 0
  }

  items.each do |item|
    timeline_column = item["column_values"].find { |cv| cv["type"] == "timeline" }
    status_column = item["column_values"].find { |cv| cv["type"] == "status" }
    status = status_column&.dig("text")&.downcase || ""
    is_completed = status.include?("done") || status.include?("completed")

    unless timeline_column && timeline_column["value"]
      timeline_stats[:no_timeline] += 1
      next
    end

    begin
      value = JSON.parse(timeline_column["value"])
      start_date = value["from"] ? Date.parse(value["from"]) : nil
      end_date = value["to"] ? Date.parse(value["to"]) : nil

      next unless end_date

      if is_completed
        # Check if completed on time
        updated_at = item["updated_at"] ? Date.parse(item["updated_at"]) : today
        if updated_at <= end_date
          timeline_stats[:completed_on_time] += 1
        else
          timeline_stats[:completed_late] += 1
        end
      else
        # Active items
        days_until_due = (end_date - today).to_i

        if days_until_due < 0
          timeline_stats[:delayed] += 1
        elsif days_until_due <= 7
          timeline_stats[:at_risk] += 1
        else
          timeline_stats[:on_time] += 1
        end
      end
    rescue JSON::ParserError, Date::Error
      timeline_stats[:no_timeline] += 1
    end
  end

  timeline_stats
end

# Usage
project_data.each do |board_id, data|
  stats = analyze_timeline_performance(data["items"])
  total = data["items"].length

  puts "\n#{data['board']['name']} - Timeline Performance:"
  puts "  Active Items:"
  puts "    On Time: #{stats[:on_time]}"
  puts "    At Risk (< 7 days): #{stats[:at_risk]}"
  puts "    Delayed: #{stats[:delayed]}"
  puts "  Completed Items:"
  puts "    On Time: #{stats[:completed_on_time]}"
  puts "    Late: #{stats[:completed_late]}"
  puts "  No Timeline: #{stats[:no_timeline]}"
end
```

### Calculate Status Distribution

```ruby
def calculate_status_distribution(items)
  distribution = Hash.new(0)

  items.each do |item|
    status_column = item["column_values"].find { |cv| cv["type"] == "status" }
    status = status_column&.dig("text") || "No Status"
    distribution[status] += 1
  end

  distribution.sort_by { |status, count| -count }.to_h
end

# Usage
project_data.each do |board_id, data|
  distribution = calculate_status_distribution(data["items"])

  puts "\n#{data['board']['name']} - Status Distribution:"
  distribution.each do |status, count|
    percentage = (count.to_f / data["items"].length * 100).round(1)
    puts "  #{status}: #{count} (#{percentage}%)"
  end
end
```

## Step 4: Generate Reports

Create comprehensive reports in multiple formats.

### Project Summary Report

```ruby
def generate_project_summary(client, project_data)
  summary = {
    generated_at: Time.now.iso8601,
    total_projects: project_data.keys.length,
    projects: []
  }

  project_data.each do |board_id, data|
    board = data["board"]
    items = data["items"]

    project_summary = {
      board_id: board["id"],
      board_name: board["name"],
      description: board["description"],
      metrics: {
        total_items: items.length,
        completion_rate: calculate_completion_rate(items),
        overdue_count: count_overdue_items(items).length,
        status_distribution: calculate_status_distribution(items),
        timeline_performance: analyze_timeline_performance(items),
        team_workload: calculate_team_workload(items)
      },
      health_score: nil  # Calculate below
    }

    # Calculate health score (0-100)
    completion = project_summary[:metrics][:completion_rate]
    overdue_ratio = items.length > 0 ? (project_summary[:metrics][:overdue_count].to_f / items.length * 100) : 0
    timeline = project_summary[:metrics][:timeline_performance]
    active_items = timeline[:on_time] + timeline[:at_risk] + timeline[:delayed]
    on_time_ratio = active_items > 0 ? (timeline[:on_time].to_f / active_items * 100) : 100

    health_score = (
      (completion * 0.3) +           # 30% weight on completion
      ((100 - overdue_ratio) * 0.4) + # 40% weight on not being overdue
      (on_time_ratio * 0.3)           # 30% weight on timeline performance
    ).round(2)

    project_summary[:health_score] = health_score
    summary[:projects] << project_summary
  end

  # Sort projects by health score
  summary[:projects].sort_by! { |p| -p[:health_score] }

  summary
end

# Usage
summary = generate_project_summary(client, project_data)

puts "\n" + "=" * 70
puts "PROJECT SUMMARY REPORT"
puts "Generated: #{summary[:generated_at]}"
puts "=" * 70

summary[:projects].each do |project|
  puts "\n#{project[:board_name]}"
  puts "  Health Score: #{project[:health_score]}/100"
  puts "  Completion: #{project[:metrics][:completion_rate]}%"
  puts "  Total Items: #{project[:metrics][:total_items]}"
  puts "  Overdue: #{project[:metrics][:overdue_count]}"
end
```

### Team Performance Report

```ruby
def generate_team_performance_report(project_data)
  global_workload = Hash.new { |h, k| h[k] = { total: 0, active: 0, completed: 0, boards: [] } }

  project_data.each do |board_id, data|
    board_workload = calculate_team_workload(data["items"])

    board_workload.each do |person, stats|
      global_workload[person][:total] += stats[:total]
      global_workload[person][:active] += stats[:active]
      global_workload[person][:completed] += stats[:completed]
      global_workload[person][:boards] << data["board"]["name"] unless global_workload[person][:boards].include?(data["board"]["name"])
    end
  end

  report = {
    generated_at: Time.now.iso8601,
    team_members: []
  }

  global_workload.each do |name, stats|
    completion_rate = stats[:total] > 0 ? (stats[:completed].to_f / stats[:total] * 100).round(2) : 0

    report[:team_members] << {
      name: name,
      total_items: stats[:total],
      active_items: stats[:active],
      completed_items: stats[:completed],
      completion_rate: completion_rate,
      boards_involved: stats[:boards]
    }
  end

  # Sort by total workload
  report[:team_members].sort_by! { |tm| -tm[:total_items] }

  report
end

# Usage
team_report = generate_team_performance_report(project_data)

puts "\n" + "=" * 70
puts "TEAM PERFORMANCE REPORT"
puts "Generated: #{team_report[:generated_at]}"
puts "=" * 70

team_report[:team_members].each do |member|
  puts "\n#{member[:name]}"
  puts "  Total Items: #{member[:total_items]}"
  puts "  Active: #{member[:active_items]} | Completed: #{member[:completed_items]}"
  puts "  Completion Rate: #{member[:completion_rate]}%"
  puts "  Involved in: #{member[:boards_involved].join(', ')}"
end
```

### Timeline Report

```ruby
def generate_timeline_report(project_data)
  report = {
    generated_at: Time.now.iso8601,
    projects: []
  }

  project_data.each do |board_id, data|
    timeline_perf = analyze_timeline_performance(data["items"])
    overdue = count_overdue_items(data["items"])

    project_timeline = {
      board_name: data["board"]["name"],
      board_id: board_id,
      timeline_performance: timeline_perf,
      overdue_items: overdue.map do |oi|
        {
          id: oi["item"]["id"],
          name: oi["item"]["name"],
          due_date: oi["due_date"].to_s,
          days_overdue: oi["days_overdue"]
        }
      end.sort_by { |item| -item[:days_overdue] }
    }

    report[:projects] << project_timeline
  end

  report
end

# Usage
timeline_report = generate_timeline_report(project_data)

puts "\n" + "=" * 70
puts "TIMELINE REPORT"
puts "Generated: #{timeline_report[:generated_at]}"
puts "=" * 70

timeline_report[:projects].each do |project|
  puts "\n#{project[:board_name]}"
  perf = project[:timeline_performance]

  puts "  Active Items:"
  puts "    ✓ On Time: #{perf[:on_time]}"
  puts "    ⚠ At Risk: #{perf[:at_risk]}"
  puts "    ✗ Delayed: #{perf[:delayed]}"

  if project[:overdue_items].any?
    puts "  Most Overdue Items:"
    project[:overdue_items].first(5).each do |item|
      puts "    • #{item[:name]} (#{item[:days_overdue]} days)"
    end
  end
end
```

### Export to JSON

```ruby
def export_to_json(report, filename)
  File.write(filename, JSON.pretty_generate(report))
  puts "✓ Exported to #{filename}"
end

# Usage
export_to_json(summary, "project_summary.json")
export_to_json(team_report, "team_performance.json")
export_to_json(timeline_report, "timeline_report.json")
```

### Export to CSV

```ruby
def export_projects_to_csv(summary, filename)
  CSV.open(filename, "w") do |csv|
    # Headers
    csv << [
      "Board Name",
      "Health Score",
      "Total Items",
      "Completion Rate (%)",
      "Overdue Items",
      "On Time",
      "At Risk",
      "Delayed"
    ]

    # Data rows
    summary[:projects].each do |project|
      timeline = project[:metrics][:timeline_performance]
      csv << [
        project[:board_name],
        project[:health_score],
        project[:metrics][:total_items],
        project[:metrics][:completion_rate],
        project[:metrics][:overdue_count],
        timeline[:on_time],
        timeline[:at_risk],
        timeline[:delayed]
      ]
    end
  end

  puts "✓ Exported to #{filename}"
end

def export_team_to_csv(team_report, filename)
  CSV.open(filename, "w") do |csv|
    # Headers
    csv << [
      "Team Member",
      "Total Items",
      "Active Items",
      "Completed Items",
      "Completion Rate (%)",
      "Boards Involved"
    ]

    # Data rows
    team_report[:team_members].each do |member|
      csv << [
        member[:name],
        member[:total_items],
        member[:active_items],
        member[:completed_items],
        member[:completion_rate],
        member[:boards_involved].join("; ")
      ]
    end
  end

  puts "✓ Exported to #{filename}"
end

# Usage
export_projects_to_csv(summary, "projects.csv")
export_team_to_csv(team_report, "team_performance.csv")
```

## Step 5: Real-time Dashboard Data

Prepare data for dashboard display with current state and KPIs.

### Calculate Dashboard KPIs

```ruby
def calculate_dashboard_kpis(project_data)
  kpis = {
    total_projects: project_data.keys.length,
    total_items: 0,
    completed_items: 0,
    active_items: 0,
    overdue_items: 0,
    at_risk_items: 0,
    team_members: Set.new,
    average_health_score: 0,
    projects_at_risk: 0  # Health score < 60
  }

  health_scores = []

  project_data.each do |board_id, data|
    items = data["items"]
    kpis[:total_items] += items.length

    # Count statuses
    items.each do |item|
      status_column = item["column_values"].find { |cv| cv["type"] == "status" }
      status = status_column&.dig("text")&.downcase || ""

      if status.include?("done") || status.include?("completed")
        kpis[:completed_items] += 1
      else
        kpis[:active_items] += 1
      end

      # Track team members
      person_column = item["column_values"].find { |cv| cv["type"] == "people" }
      if person_column && person_column["text"]
        kpis[:team_members].add(person_column["text"])
      end
    end

    # Overdue and at-risk counts
    overdue = count_overdue_items(items)
    timeline_perf = analyze_timeline_performance(items)

    kpis[:overdue_items] += overdue.length
    kpis[:at_risk_items] += timeline_perf[:at_risk]

    # Calculate health score for this project
    completion = calculate_completion_rate(items)
    overdue_ratio = items.length > 0 ? (overdue.length.to_f / items.length * 100) : 0
    active_items = timeline_perf[:on_time] + timeline_perf[:at_risk] + timeline_perf[:delayed]
    on_time_ratio = active_items > 0 ? (timeline_perf[:on_time].to_f / active_items * 100) : 100

    health_score = (
      (completion * 0.3) +
      ((100 - overdue_ratio) * 0.4) +
      (on_time_ratio * 0.3)
    ).round(2)

    health_scores << health_score
    kpis[:projects_at_risk] += 1 if health_score < 60
  end

  kpis[:average_health_score] = health_scores.empty? ? 0 : (health_scores.sum / health_scores.length).round(2)
  kpis[:team_members] = kpis[:team_members].size

  kpis
end

# Usage
kpis = calculate_dashboard_kpis(project_data)

puts "\n" + "=" * 70
puts "DASHBOARD KPIs"
puts "=" * 70
puts "Total Projects: #{kpis[:total_projects]}"
puts "Total Items: #{kpis[:total_items]}"
puts "  Active: #{kpis[:active_items]}"
puts "  Completed: #{kpis[:completed_items]}"
puts "  Overdue: #{kpis[:overdue_items]}"
puts "  At Risk: #{kpis[:at_risk_items]}"
puts "\nTeam Members: #{kpis[:team_members]}"
puts "Average Health Score: #{kpis[:average_health_score]}/100"
puts "Projects at Risk: #{kpis[:projects_at_risk]}"
```

### Format for Dashboard Widgets

```ruby
def format_for_dashboard(project_data)
  dashboard = {
    timestamp: Time.now.iso8601,
    kpis: calculate_dashboard_kpis(project_data),
    projects: [],
    recent_updates: [],
    alerts: []
  }

  # Project widgets
  project_data.each do |board_id, data|
    items = data["items"]
    completion = calculate_completion_rate(items)
    overdue = count_overdue_items(items)
    timeline_perf = analyze_timeline_performance(items)

    dashboard[:projects] << {
      id: board_id,
      name: data["board"]["name"],
      completion_percentage: completion,
      total_items: items.length,
      overdue_count: overdue.length,
      status_breakdown: calculate_status_distribution(items),
      timeline: {
        on_time: timeline_perf[:on_time],
        at_risk: timeline_perf[:at_risk],
        delayed: timeline_perf[:delayed]
      }
    }

    # Generate alerts for critical items
    if overdue.length > 0
      dashboard[:alerts] << {
        severity: "high",
        project: data["board"]["name"],
        message: "#{overdue.length} overdue items",
        items: overdue.first(3).map { |oi| { name: oi["item"]["name"], days: oi["days_overdue"] } }
      }
    end

    if timeline_perf[:at_risk] > 5
      dashboard[:alerts] << {
        severity: "medium",
        project: data["board"]["name"],
        message: "#{timeline_perf[:at_risk]} items due within 7 days"
      }
    end

    # Recent updates (last 5 updated items)
    recent = items.sort_by { |item| item["updated_at"] || "" }.reverse.first(5)
    recent.each do |item|
      dashboard[:recent_updates] << {
        project: data["board"]["name"],
        item_name: item["name"],
        updated_at: item["updated_at"]
      }
    end
  end

  # Sort alerts by severity
  dashboard[:alerts].sort_by! { |alert| alert[:severity] == "high" ? 0 : 1 }

  # Keep only 10 most recent updates
  dashboard[:recent_updates] = dashboard[:recent_updates].sort_by { |u| u[:updated_at] || "" }.reverse.first(10)

  dashboard
end

# Usage
dashboard_data = format_for_dashboard(project_data)

puts "\n" + "=" * 70
puts "DASHBOARD DATA"
puts "=" * 70

# Show alerts
puts "\nAlerts (#{dashboard_data[:alerts].length}):"
dashboard_data[:alerts].each do |alert|
  severity_icon = alert[:severity] == "high" ? "🔴" : "🟡"
  puts "  #{severity_icon} #{alert[:project]}: #{alert[:message]}"
end

# Export dashboard data
export_to_json(dashboard_data, "dashboard_data.json")
```

## Step 6: Workspace Overview

Get high-level metrics across all projects in the workspace.

### Workspace-Level Metrics

```ruby
def generate_workspace_overview(client, workspace_id, project_data)
  overview = {
    workspace_id: workspace_id,
    generated_at: Time.now.iso8601,
    summary: {
      total_projects: project_data.keys.length,
      total_items: 0,
      total_completed: 0,
      overall_completion_rate: 0,
      total_overdue: 0,
      projects_on_track: 0,
      projects_at_risk: 0,
      projects_critical: 0
    },
    project_breakdown: []
  }

  project_data.each do |board_id, data|
    items = data["items"]
    completion = calculate_completion_rate(items)
    overdue = count_overdue_items(items)
    timeline_perf = analyze_timeline_performance(items)

    overview[:summary][:total_items] += items.length

    completed_count = items.count do |item|
      status_column = item["column_values"].find { |cv| cv["type"] == "status" }
      status = status_column&.dig("text")&.downcase || ""
      status.include?("done") || status.include?("completed")
    end
    overview[:summary][:total_completed] += completed_count
    overview[:summary][:total_overdue] += overdue.length

    # Calculate health score
    overdue_ratio = items.length > 0 ? (overdue.length.to_f / items.length * 100) : 0
    active_items = timeline_perf[:on_time] + timeline_perf[:at_risk] + timeline_perf[:delayed]
    on_time_ratio = active_items > 0 ? (timeline_perf[:on_time].to_f / active_items * 100) : 100

    health_score = (
      (completion * 0.3) +
      ((100 - overdue_ratio) * 0.4) +
      (on_time_ratio * 0.3)
    ).round(2)

    # Categorize project health
    if health_score >= 80
      overview[:summary][:projects_on_track] += 1
      status = "on_track"
    elsif health_score >= 60
      overview[:summary][:projects_at_risk] += 1
      status = "at_risk"
    else
      overview[:summary][:projects_critical] += 1
      status = "critical"
    end

    overview[:project_breakdown] << {
      name: data["board"]["name"],
      health_score: health_score,
      status: status,
      completion_rate: completion,
      total_items: items.length,
      overdue_items: overdue.length
    }
  end

  # Calculate overall completion rate
  overview[:summary][:overall_completion_rate] = if overview[:summary][:total_items] > 0
    (overview[:summary][:total_completed].to_f / overview[:summary][:total_items] * 100).round(2)
  else
    0
  end

  # Sort projects by health score
  overview[:project_breakdown].sort_by! { |p| -p[:health_score] }

  overview
end

# Usage
workspace_overview = generate_workspace_overview(client, workspace_id, project_data)

puts "\n" + "=" * 70
puts "WORKSPACE OVERVIEW"
puts "=" * 70
puts "Total Projects: #{workspace_overview[:summary][:total_projects]}"
puts "Total Items: #{workspace_overview[:summary][:total_items]}"
puts "Overall Completion: #{workspace_overview[:summary][:overall_completion_rate]}%"
puts "Total Overdue: #{workspace_overview[:summary][:total_overdue]}"
puts "\nProject Health:"
puts "  ✓ On Track: #{workspace_overview[:summary][:projects_on_track]}"
puts "  ⚠ At Risk: #{workspace_overview[:summary][:projects_at_risk]}"
puts "  ✗ Critical: #{workspace_overview[:summary][:projects_critical]}"

puts "\nProject Breakdown:"
workspace_overview[:project_breakdown].each do |project|
  status_icon = case project[:status]
  when "on_track" then "✓"
  when "at_risk" then "⚠"
  when "critical" then "✗"
  end

  puts "  #{status_icon} #{project[:name]} - Health: #{project[:health_score]}/100"
end
```

### Identify At-Risk Projects

```ruby
def identify_at_risk_projects(workspace_overview)
  at_risk = workspace_overview[:project_breakdown].select do |project|
    project[:status] == "at_risk" || project[:status] == "critical"
  end

  report = {
    generated_at: Time.now.iso8601,
    at_risk_count: at_risk.length,
    projects: at_risk.map do |project|
      {
        name: project[:name],
        health_score: project[:health_score],
        status: project[:status],
        issues: []
      }
    end
  }

  # Add specific issues
  report[:projects].each do |project|
    if project[:health_score] < 40
      project[:issues] << "Critical health score"
    end

    original_project = workspace_overview[:project_breakdown].find { |p| p[:name] == project[:name] }

    if original_project[:completion_rate] < 30
      project[:issues] << "Low completion rate (#{original_project[:completion_rate]}%)"
    end

    if original_project[:overdue_items] > 5
      project[:issues] << "High number of overdue items (#{original_project[:overdue_items]})"
    end
  end

  report
end

# Usage
at_risk_report = identify_at_risk_projects(workspace_overview)

puts "\n" + "=" * 70
puts "AT-RISK PROJECTS REPORT"
puts "=" * 70
puts "#{at_risk_report[:at_risk_count]} projects need attention\n"

at_risk_report[:projects].each do |project|
  puts "\n#{project[:name]} (Health: #{project[:health_score]}/100)"
  puts "  Status: #{project[:status].upcase}"
  puts "  Issues:"
  project[:issues].each do |issue|
    puts "    • #{issue}"
  end
end

export_to_json(at_risk_report, "at_risk_projects.json")
```

## Step 7: Complete Dashboard Example

Putting it all together in a single dashboard collector script.

```ruby
require "monday_ruby"
require "json"
require "csv"
require "date"
require "set"

Monday.configure do |config|
  config.token = ENV["MONDAY_TOKEN"]
end

class ProjectDashboard
  attr_reader :client, :workspace_id, :project_data

  def initialize(workspace_id)
    @client = Monday::Client.new
    @workspace_id = workspace_id
    @project_data = {}
  end

  # Collect all project data
  def collect_data
    puts "Collecting project data..."

    # Get all boards in workspace
    boards = get_workspace_boards

    # Filter to project boards
    project_boards = identify_project_boards(boards)

    # Aggregate data from all project boards
    aggregate_project_data(project_boards)

    puts "✓ Data collection complete: #{@project_data.keys.length} projects"
  end

  # Generate all reports
  def generate_reports
    puts "\nGenerating reports..."

    reports = {
      summary: generate_project_summary,
      team: generate_team_performance_report,
      timeline: generate_timeline_report,
      kpis: calculate_dashboard_kpis,
      workspace: generate_workspace_overview,
      at_risk: identify_at_risk_projects
    }

    puts "✓ All reports generated"
    reports
  end

  # Export all data
  def export_all(reports)
    puts "\nExporting data..."

    # JSON exports
    File.write("reports/summary.json", JSON.pretty_generate(reports[:summary]))
    File.write("reports/team.json", JSON.pretty_generate(reports[:team]))
    File.write("reports/timeline.json", JSON.pretty_generate(reports[:timeline]))
    File.write("reports/kpis.json", JSON.pretty_generate(reports[:kpis]))
    File.write("reports/workspace.json", JSON.pretty_generate(reports[:workspace]))
    File.write("reports/at_risk.json", JSON.pretty_generate(reports[:at_risk]))

    # CSV exports
    export_projects_csv(reports[:summary])
    export_team_csv(reports[:team])

    # Dashboard data
    dashboard_data = format_for_dashboard
    File.write("reports/dashboard.json", JSON.pretty_generate(dashboard_data))

    puts "✓ All data exported to ./reports/"
  end

  # Display summary
  def display_summary(reports)
    puts "\n" + "=" * 70
    puts "PROJECT DASHBOARD SUMMARY"
    puts "Generated: #{Time.now}"
    puts "=" * 70

    kpis = reports[:kpis]
    puts "\nKEY METRICS"
    puts "  Projects: #{kpis[:total_projects]}"
    puts "  Total Items: #{kpis[:total_items]}"
    puts "  Completed: #{kpis[:completed_items]}"
    puts "  Overdue: #{kpis[:overdue_items]}"
    puts "  At Risk: #{kpis[:at_risk_items]}"
    puts "  Average Health: #{kpis[:average_health_score]}/100"

    puts "\nTOP PERFORMERS"
    reports[:summary][:projects].first(3).each_with_index do |project, i|
      puts "  #{i + 1}. #{project[:board_name]} (Health: #{project[:health_score]}/100)"
    end

    puts "\nNEED ATTENTION"
    reports[:at_risk][:projects].first(3).each do |project|
      puts "  ⚠ #{project[:name]} (Health: #{project[:health_score]}/100)"
    end

    puts "\n" + "=" * 70
  end

  private

  def get_workspace_boards
    response = @client.board.query(
      args: { workspace_ids: [@workspace_id] },
      select: [
        "id", "name", "description", "state",
        { groups: ["id", "title"], columns: ["id", "title", "type"] }
      ]
    )

    response.success? ? response.body.dig("data", "boards") || [] : []
  end

  def identify_project_boards(boards)
    boards.select do |board|
      board["columns"].any? { |col| col["type"] == "status" } &&
      (board["columns"].any? { |col| col["type"] == "timeline" } ||
       board["name"].match?(/project/i))
    end
  end

  def aggregate_project_data(project_boards)
    project_boards.each do |board|
      items = fetch_all_board_items(board["id"])
      @project_data[board["id"]] = {
        "board" => board,
        "items" => items,
        "total_items" => items.length
      }
    end
  end

  def fetch_all_board_items(board_id)
    all_items = []
    cursor = nil

    loop do
      response = @client.board.items_page(
        board_ids: board_id,
        limit: 100,
        cursor: cursor,
        select: [
          "id", "name", "state", "created_at", "updated_at",
          { group: ["id", "title"], column_values: ["id", "text", "type", "value"] }
        ]
      )

      break unless response.success?

      items_page = response.body.dig("data", "boards", 0, "items_page")
      items = items_page["items"] || []
      break if items.empty?

      all_items.concat(items)
      cursor = items_page["cursor"]
      break if cursor.nil?
    end

    all_items
  end

  # Include all the helper methods from previous sections:
  # - calculate_completion_rate
  # - count_overdue_items
  # - calculate_team_workload
  # - analyze_timeline_performance
  # - calculate_status_distribution
  # - generate_project_summary
  # - generate_team_performance_report
  # - generate_timeline_report
  # - calculate_dashboard_kpis
  # - generate_workspace_overview
  # - identify_at_risk_projects
  # - format_for_dashboard
  # - export_projects_csv
  # - export_team_csv
end

# Usage
dashboard = ProjectDashboard.new(1234567)  # Your workspace ID

# Collect data
dashboard.collect_data

# Generate reports
reports = dashboard.generate_reports

# Export everything
Dir.mkdir("reports") unless Dir.exist?("reports")
dashboard.export_all(reports)

# Display summary
dashboard.display_summary(reports)
```

## Running the Dashboard

```bash
# Set your API token
export MONDAY_TOKEN="your_token_here"

# Run the dashboard
ruby project_dashboard.rb

# Output:
# Collecting project data...
# ✓ Data collection complete: 5 projects
#
# Generating reports...
# ✓ All reports generated
#
# Exporting data...
# ✓ All data exported to ./reports/
#
# ======================================================================
# PROJECT DASHBOARD SUMMARY
# Generated: 2024-01-15 10:30:00
# ======================================================================
#
# KEY METRICS
#   Projects: 5
#   Total Items: 247
#   Completed: 156
#   Overdue: 12
#   At Risk: 8
#   Average Health: 78.5/100
# ...
```

## Best Practices

### 1. Handle Rate Limits

Add delays between large queries:

```ruby
def fetch_all_board_items(board_id)
  # ... pagination logic ...

  sleep(0.5) unless cursor.nil?  # Add delay between pages
end
```

### 2. Cache Results

Store intermediate results to avoid re-fetching:

```ruby
def collect_data_with_cache
  cache_file = "cache/project_data_#{Date.today}.json"

  if File.exist?(cache_file) && File.mtime(cache_file) > (Time.now - 3600)
    puts "Loading from cache..."
    @project_data = JSON.parse(File.read(cache_file))
  else
    collect_data
    File.write(cache_file, JSON.pretty_generate(@project_data))
  end
end
```

### 3. Error Handling

Add robust error handling:

```ruby
def fetch_all_board_items(board_id)
  all_items = []
  cursor = nil
  retry_count = 0

  loop do
    begin
      response = @client.board.items_page(
        board_ids: board_id,
        limit: 100,
        cursor: cursor
      )

      # ... process response ...

    rescue Monday::ComplexityException => e
      if retry_count < 3
        retry_count += 1
        sleep(60)
        retry
      else
        puts "Max retries exceeded for board #{board_id}"
        break
      end
    end
  end

  all_items
end
```

### 4. Incremental Updates

Only fetch items updated since last run:

```ruby
def fetch_recent_updates(board_id, since_date)
  # Use updated_at in your filtering logic
  items = fetch_all_board_items(board_id)

  items.select do |item|
    updated_at = Date.parse(item["updated_at"])
    updated_at >= since_date
  rescue
    false
  end
end
```

## Next Steps

- [Pagination guide](/guides/advanced/pagination) - Efficient data fetching
- [Error handling](/guides/advanced/errors) - Robust error management
- [Complex queries](/guides/advanced/complex-queries) - Advanced data retrieval
- [Rate limiting](/guides/advanced/rate-limiting) - API usage optimization
