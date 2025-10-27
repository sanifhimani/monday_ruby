# frozen_string_literal: true

RSpec.describe Monday::Resources::Item, :vcr do
  describe ".query" do
    subject(:response) { client.item.query(args: args, select: select) }

    let(:select) { %w[id name created_at] }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when an invalid field is requested" do
        let(:test_data) { create_test_board_with_item(client, board_name: "Query Invalid Field Test") }
        let(:board_id) { test_data[:board_id] }
        let(:item_id) { test_data[:item_id] }
        let(:args) { { ids: item_id } }
        let(:select) { ["invalid_field"] }

        after do
          safely_delete_board(client, board_id)
        end

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when an item does not exist for the given item_id" do
        let(:args) { { ids: "123" } }

        it "returns an empty array" do
          expect(response.body["data"]["items"]).to eq([])
        end
      end

      context "when the args are valid" do
        let(:test_data) { create_test_board_with_item(client, board_name: "Query Test Board") }
        let(:board_id) { test_data[:board_id] }
        let(:item_id) { test_data[:item_id] }
        let(:args) { { ids: item_id } }

        after do
          safely_delete_board(client, board_id)
        end

        it_behaves_like "authenticated client request"

        it "returns the body with item ID, name and created_at" do
          expect(
            response.body["data"]["items"]
          ).to match(array_including(hash_including("id", "name", "created_at")))
        end
      end
    end
  end

  describe ".create" do
    subject(:response) { client.item.create(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when the board does not exist for the given board_id" do
        let(:args) do
          {
            board_id: "123",
            item_name: "Test Item",
            column_values: {
              status__1: { # rubocop:disable Naming/VariableNumber
                label: "Done"
              }
            }
          }
        end

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidBoardIdException:/
          )
        end
      end

      context "when the args are valid" do
        let(:test_data) { create_test_board_with_items(client, board_name: "Create Test Board", item_count: 0) }
        let(:board_id) { test_data[:board_id] }
        let(:args) do
          {
            board_id: board_id,
            item_name: "Test Item",
            column_values: {
              status__1: { # rubocop:disable Naming/VariableNumber
                label: "Done"
              }
            }
          }
        end

        after do
          safely_delete_board(client, board_id)
        end

        it_behaves_like "authenticated client request"

        it "returns the body with the created item ID" do
          expect(
            response.body["data"]["create_item"]
          ).to match(hash_including("id"))
        end
      end
    end
  end

  describe ".duplicate" do
    subject(:response) { client.item.duplicate(board_id, item_id, with_updates) }

    let(:with_updates) { true }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:board_id) { "123" }
      let(:item_id) { "123" }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when the board does not exist for the given board_id" do
        let(:board_id) { "123" }
        let(:item_id) { "123" }

        it "raises Monday::InternalServerError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end

      context "when the item does not exist for the given item_id" do
        let(:test_data) { create_test_board_with_items(client, board_name: "Duplicate Test Board", item_count: 0) }
        let(:board_id) { test_data[:board_id] }
        let(:item_id) { "123" }

        after do
          safely_delete_board(client, board_id)
        end

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidItemIdException:/
          )
        end
      end

      context "when the args are valid" do
        let(:test_data) { create_test_board_with_item(client, board_name: "Duplicate Valid Test") }
        let(:board_id) { test_data[:board_id] }
        let(:item_id) { test_data[:item_id] }

        after do
          safely_delete_board(client, board_id)
        end

        it_behaves_like "authenticated client request"

        it "returns the body with the duplicated item ID" do
          expect(
            response.body["data"]["duplicate_item"]
          ).to match(hash_including("id"))
        end
      end
    end
  end

  describe ".archive" do
    subject(:response) { client.item.archive(item_id) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:item_id) { "123" }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when the item does not exist for the given item_id" do
        let(:item_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidItemIdException:/
          )
        end
      end

      context "when the item exists" do
        let(:test_data) { create_test_board_with_item(client, board_name: "Archive Test Board") }
        let(:board_id) { test_data[:board_id] }
        let(:item_id) { test_data[:item_id] }

        after do
          safely_delete_board(client, board_id)
        end

        it_behaves_like "authenticated client request"

        it "returns the body with the archived item ID" do
          expect(
            response.body["data"]["archive_item"]
          ).to match(hash_including("id"))
        end
      end
    end
  end

  describe ".delete" do
    subject(:response) { client.item.delete(item_id) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:item_id) { "123" }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when the item does not exist for the given item_id" do
        let(:item_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidItemIdException:/
          )
        end
      end

      context "when the item exists" do
        let(:test_data) { create_test_board_with_item(client, board_name: "Delete Test Board") }
        let(:board_id) { test_data[:board_id] }
        let(:item_id) { test_data[:item_id] }

        after do
          safely_delete_board(client, board_id)
        end

        it_behaves_like "authenticated client request"

        it "returns the body with the deleted item ID" do
          expect(
            response.body["data"]["delete_item"]
          ).to match(hash_including("id"))
        end
      end
    end
  end

  describe ".page_by_column_values" do
    subject(:response) do
      client.item.page_by_column_values(
        board_id: board_id,
        columns: columns,
        limit: limit,
        cursor: cursor
      )
    end

    let(:limit) { 25 }
    let(:cursor) { nil }
    let(:columns) { nil }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:board_id) { "123456" }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when the board does not exist" do
        let(:board_id) { "123456" }
        let(:columns) { [{ column_id: "status", column_values: ["Done"] }] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when filtering by column values" do
        context "with a single column filter" do
          let(:test_data) do
            create_test_board_with_items(client, board_name: "Column Filter Test Board", item_count: 10)
          end
          let(:board_id) { test_data[:board_id] }
          let(:columns) { [{ column_id: "name", column_values: ["Test Item 1"] }] }

          after do
            safely_delete_board(client, board_id)
          end

          it_behaves_like "authenticated client request"

          it "returns items_page structure with cursor and items" do
            items_page = response.body.dig("data", "items_page_by_column_values")

            expect(items_page).to include("cursor", "items")
          end

          it "returns items with default fields (id, name)" do
            items = response.body.dig("data", "items_page_by_column_values", "items")

            expect(items).to be_an(Array)
            expect(items).to all(include("id", "name"))
          end
        end

        context "with multiple column filters (AND logic)" do
          let(:test_data) do
            create_test_board_with_items(
              client,
              board_name: "Column Filter Test Board",
              item_count: 10,
              create_status_column: true
            )
          end
          let(:board_id) { test_data[:board_id] }
          let(:status_column_id) { test_data[:status_column_id] }
          let(:columns) do
            [
              { column_id: "name", column_values: ["Test Item 1", "Test Item 2"] },
              { column_id: status_column_id, column_values: ["Done"] }
            ]
          end

          after do
            safely_delete_board(client, board_id)
          end

          it "returns filtered items based on all column criteria" do
            items_page = response.body.dig("data", "items_page_by_column_values")

            expect(items_page).to include("cursor", "items")
            expect(items_page["items"]).to be_an(Array)
          end
        end

        context "with column values using ANY_OF logic within a column" do
          let(:test_data) do
            create_test_board_with_items(client, board_name: "Column Filter Test Board", item_count: 10)
          end
          let(:board_id) { test_data[:board_id] }
          let(:columns) { [{ column_id: "name", column_values: ["Test Item 1", "Test Item 2", "Test Item 3"] }] }

          after do
            safely_delete_board(client, board_id)
          end

          it "returns items matching any of the values in the column" do
            items_page = response.body.dig("data", "items_page_by_column_values")

            expect(items_page).to include("cursor", "items")
            expect(items_page["items"]).to be_an(Array)
          end
        end
      end

      context "when using pagination" do
        let(:test_data) { create_test_board_with_items(client, board_name: "Pagination Test Board", item_count: 15) }
        let(:board_id) { test_data[:board_id] }
        let(:limit) { 5 }

        after do
          safely_delete_board(client, board_id)
        end

        context "with limit parameter" do
          let(:columns) { [{ column_id: "name", column_values: test_data[:item_ids].map { |_| "Test Item" } }] }

          it "returns the requested number of items" do
            items = response.body.dig("data", "items_page_by_column_values", "items")

            expect(items.length).to be <= limit
          end

          it "returns a cursor for the next page if more items exist" do
            cursor_value = response.body.dig("data", "items_page_by_column_values", "cursor")

            expect(cursor_value).to be_a(String).or be_nil
          end
        end

        context "with cursor for next page" do
          it "paginates through items without duplicates using cursor" do
            first_page = client.item.page_by_column_values(
              board_id: board_id,
              columns: [{ column_id: "name", column_values: ["Test Item 1", "Test Item 2", "Test Item 3"] }],
              limit: 1
            )

            first_page_items = first_page.body.dig("data", "items_page_by_column_values", "items")
            cursor = first_page.body.dig("data", "items_page_by_column_values", "cursor")

            expect(first_page_items).to be_an(Array)
            expect(first_page_items.length).to eq(1)
            expect(cursor).to be_a(String)

            second_page = client.item.page_by_column_values(
              board_id: board_id,
              cursor: cursor,
              limit: 1
            )

            second_page_items = second_page.body.dig("data", "items_page_by_column_values", "items")

            expect(second_page_items).to be_an(Array)

            first_page_ids = first_page_items.map { |item| item["id"] }
            second_page_ids = second_page_items.map { |item| item["id"] }
            expect(first_page_ids & second_page_ids).to be_empty
          end
        end
      end

      context "when requesting custom select fields" do
        subject(:response) do
          client.item.page_by_column_values(
            board_id: board_id,
            columns: [{ column_id: "name", column_values: ["Test Item"] }],
            limit: 5,
            select: %w[id name state created_at]
          )
        end

        let(:test_data) { create_test_board_with_items(client, board_name: "Custom Fields Test Board", item_count: 5) }
        let(:board_id) { test_data[:board_id] }

        after do
          safely_delete_board(client, board_id)
        end

        it "returns items with requested fields" do
          items = response.body.dig("data", "items_page_by_column_values", "items")

          expect(items).to all(include("id", "name", "state", "created_at"))
        end
      end

      context "when no items match the filter criteria" do
        let(:test_data) { create_test_board_with_items(client, board_name: "No Match Test Board", item_count: 5) }
        let(:board_id) { test_data[:board_id] }
        let(:columns) { [{ column_id: "name", column_values: ["Non-existent Item"] }] }

        after do
          safely_delete_board(client, board_id)
        end

        it "returns empty items array" do
          items = response.body.dig("data", "items_page_by_column_values", "items")

          expect(items).to be_empty
        end

        it "returns nil cursor when no items match" do
          cursor_value = response.body.dig("data", "items_page_by_column_values", "cursor")

          expect(cursor_value).to be_nil
        end
      end

      context "when using different limit values" do
        let(:test_data) { create_test_board_with_items(client, board_name: "Limit Test Board", item_count: 10) }
        let(:board_id) { test_data[:board_id] }
        let(:columns) { [{ column_id: "name", column_values: ["Test Item"] }] }

        after do
          safely_delete_board(client, board_id)
        end

        context "with small limit (1)" do
          let(:limit) { 1 }

          it "returns only 1 item" do
            items = response.body.dig("data", "items_page_by_column_values", "items")

            expect(items.length).to be <= 1
          end
        end

        context "with large limit (100)" do
          let(:limit) { 100 }

          it "returns all matching items up to the limit" do
            items = response.body.dig("data", "items_page_by_column_values", "items")

            expect(items.length).to be <= limit
          end
        end
      end
    end
  end
end
