# frozen_string_literal: true

module BoardHelpers
  # Creates a test board with items for pagination testing
  # @param client [Monday::Client] The authenticated client
  # @param board_name [String] Name of the board to create
  # @param item_count [Integer] Number of items to create in the board
  # @param create_status_column [Boolean] Whether to create a status column (default: false)
  # @return [Hash] Hash containing board_id, item_ids, and optionally status_column_id
  def create_test_board_with_items(client, board_name: "Test Board", item_count: 5, create_status_column: false)
    # Create the board
    board_response = client.board.create(
      args: { board_name: board_name, board_kind: :private }
    )
    board_id = board_response.body.dig("data", "create_board", "id")

    # Create status column if requested
    status_column_id = nil
    if create_status_column
      status_column_response = client.column.create(
        args: {
          board_id: board_id,
          title: "Status",
          column_type: :status
        }
      )
      status_column_id = status_column_response.body.dig("data", "create_column", "id")
    end

    # Get existing items (Monday.com creates default items)
    existing_items_response = client.board.items_page(board_ids: board_id, limit: 500)
    existing_items = existing_items_response.body.dig("data", "boards", 0, "items_page", "items") || []

    # Delete all existing default items if we want 0 items
    if item_count.zero?
      existing_items.each do |item|
        client.item.delete(item["id"])
      end
      result = { board_id: board_id, item_ids: [] }
      result[:status_column_id] = status_column_id if create_status_column
      return result
    end

    # Create the requested number of items
    item_ids = []
    item_count.times do |i|
      item_response = client.item.create(
        args: {
          board_id: board_id,
          item_name: "Test Item #{i + 1}"
        }
      )
      item_ids << item_response.body.dig("data", "create_item", "id")
    end

    result = { board_id: board_id, item_ids: item_ids }
    result[:status_column_id] = status_column_id if create_status_column
    result
  end

  # Creates a test board with groups and items for group pagination testing
  # @param client [Monday::Client] The authenticated client
  # @param board_name [String] Name of the board to create
  # @param group_name [String] Name of the group to create
  # @param item_count [Integer] Number of items to create in the group
  # @return [Hash] Hash containing board_id, group_id, and item IDs
  def create_test_board_with_group_and_items(client, board_name: "Test Board", group_name: "Test Group", item_count: 5)
    # Create the board
    board_response = client.board.create(
      args: { board_name: board_name, board_kind: :private }
    )
    board_id = board_response.body.dig("data", "create_board", "id")

    # Create a group
    group_response = client.group.create(
      args: {
        board_id: board_id,
        group_name: group_name
      }
    )
    group_id = group_response.body.dig("data", "create_group", "id")

    # Create items in the group
    item_ids = []
    item_count.times do |i|
      item_response = client.item.create(
        args: {
          board_id: board_id,
          group_id: group_id,
          item_name: "Test Item #{i + 1}"
        }
      )
      item_ids << item_response.body.dig("data", "create_item", "id")
    end

    { board_id: board_id, group_id: group_id, item_ids: item_ids }
  end

  # Safely deletes a board if it exists
  # @param client [Monday::Client] The authenticated client
  # @param board_id [String, Integer] The board ID to delete
  # @return [Boolean] True if deleted, false if error occurred
  def safely_delete_board(client, board_id)
    return false unless board_id

    client.board.delete(board_id)
    true
  rescue Monday::Error
    # Board might already be deleted or doesn't exist
    false
  end

  # Safely archives a board if it exists
  # @param client [Monday::Client] The authenticated client
  # @param board_id [String, Integer] The board ID to archive
  # @return [Boolean] True if archived, false if error occurred
  def safely_archive_board(client, board_id)
    return false unless board_id

    client.board.archive(board_id)
    true
  rescue Monday::Error
    # Board might already be archived or doesn't exist
    false
  end

  # Creates a test board with a single item for simple item testing
  # @param client [Monday::Client] The authenticated client
  # @param board_name [String] Name of the board to create
  # @param item_name [String] Name of the item to create
  # @param column_values [Hash, nil] Optional column values to set on the item
  # @return [Hash] Hash containing board_id and item_id
  def create_test_board_with_item(client, board_name: "Test Board", item_name: "Test Item", column_values: nil)
    # Create the board
    board_response = client.board.create(
      args: { board_name: board_name, board_kind: :private }
    )
    board_id = board_response.body.dig("data", "create_board", "id")

    # Create the item
    item_args = {
      board_id: board_id,
      item_name: item_name
    }
    item_args[:column_values] = column_values if column_values

    item_response = client.item.create(args: item_args)
    item_id = item_response.body.dig("data", "create_item", "id")

    { board_id: board_id, item_id: item_id }
  end

  # Safely deletes an item if it exists
  # @param client [Monday::Client] The authenticated client
  # @param item_id [String, Integer] The item ID to delete
  # @return [Boolean] True if deleted, false if error occurred
  def safely_delete_item(client, item_id)
    return false unless item_id

    client.item.delete(item_id)
    true
  rescue Monday::Error
    # Item might already be deleted or doesn't exist
    false
  end
end

RSpec.configure do |config|
  config.include BoardHelpers
end
