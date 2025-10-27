# frozen_string_literal: true

RSpec.describe Monday::Resources::Board, :vcr do
  describe ".query" do
    subject(:response) { client.board.query(select: select) }

    let(:select) { %w[id name description] }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }
      let(:test_data) { create_test_board_with_items(client, board_name: "Query Test Board", item_count: 0) }
      let(:board_id) { test_data[:board_id] }

      after do
        safely_delete_board(client, board_id)
      end

      it_behaves_like "authenticated client request"

      it "returns the body with ID, name and description" do
        expect(
          response.body["data"]["boards"]
        ).to match(array_including(hash_including("id", "name", "description")))
      end

      context "when a field that doesn't exist on boards is requested" do
        let(:select) { ["invalid_field"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end
    end
  end

  describe ".create" do
    subject(:response) { client.board.create(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when args are invalid" do
        let(:args) do
          {
            board_name: "New test board",
            board_kind: "invalid_kind"
          }
        end

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when args are valid" do
        let(:args) do
          {
            board_name: "New test board",
            board_kind: :private
          }
        end

        let(:board_id) { response.body.dig("data", "create_board", "id") }

        after do
          safely_delete_board(client, board_id)
        end

        it_behaves_like "authenticated client request"

        it "returns the body with created boards ID, name and description" do
          expect(
            response.body["data"]["create_board"]
          ).to match(hash_including("id", "name", "description"))
        end
      end
    end
  end

  describe ".duplicate" do
    subject(:response) { client.board.duplicate(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }
      let(:test_data) { create_test_board_with_items(client, board_name: "Duplicate Test Board", item_count: 0) }
      let(:board_id) { test_data[:board_id] }
      let(:duplicated_board_id) { response.body.dig("data", "duplicate_board", "board", "id") }

      context "when args are invalid" do
        let(:args) do
          {
            board_id: board_id,
            duplicate_type: "invalid_type"
          }
        end

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when args are valid" do
        let(:args) do
          {
            board_id: board_id,
            duplicate_type: :duplicate_board_with_structure
          }
        end

        after do
          safely_delete_board(client, board_id)
          safely_delete_board(client, duplicated_board_id) if response&.status == 200
        end

        it_behaves_like "authenticated client request"

        it "returns the body with duplicated boards ID, name and description" do
          expect(
            response.body["data"]["duplicate_board"]["board"]
          ).to match(hash_including("id", "name", "description"))
        end
      end
    end
  end

  describe ".update" do
    subject(:response) { client.board.update(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }
      let(:test_data) { create_test_board_with_items(client, board_name: "Update Test Board", item_count: 0) }
      let(:board_id) { test_data[:board_id] }

      context "when args are invalid" do
        let(:args) do
          {
            board_id: board_id,
            board_attribute: "invalid_attribute",
            new_value: "New description"
          }
        end

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when args are valid" do
        let(:args) do
          {
            board_id: board_id,
            board_attribute: :description,
            new_value: "New description"
          }
        end

        after do
          safely_delete_board(client, board_id)
        end

        it_behaves_like "authenticated client request"

        it "returns the body with update status and undo data" do
          expect(
            JSON.parse(response.body["data"]["update_board"])
          ).to match(hash_including("success", "undo_data"))
        end
      end
    end
  end

  describe ".archive" do
    subject(:response) { client.board.archive(board_id) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:board_id) { "123456" }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when the board does not exist" do
        let(:board_id) { "123" }

        it "raises Monday::AuthorizationError error" do
          expect { response }.to raise_error(Monday::AuthorizationError)
        end
      end

      context "when the board exists" do
        let(:test_data) { create_test_board_with_items(client, board_name: "Archive Test Board", item_count: 0) }
        let(:board_id) { test_data[:board_id] }

        after do
          safely_delete_board(client, board_id) if response&.status == 200
        end

        it "returns the body with archived boards ID" do
          expect(
            response.body["data"]["archive_board"]
          ).to match(hash_including("id"))
        end
      end
    end
  end

  describe ".delete" do
    subject(:response) { client.board.delete(board_id) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:board_id) { "132456" }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when the board does not exist" do
        let(:board_id) { "123456" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidBoardIdException:/
          )
        end
      end

      context "when the board exists" do
        let(:test_data) { create_test_board_with_items(client, board_name: "Delete Test Board", item_count: 0) }
        let(:board_id) { test_data[:board_id] }

        it "returns the body with deleted boards ID" do
          expect(
            response.body["data"]["delete_board"]
          ).to match(hash_including("id"))
        end
      end
    end
  end

  describe ".items_page" do
    subject(:response) { client.board.items_page(board_ids: board_id, limit: limit, cursor: cursor) }

    let(:limit) { 5 }
    let(:cursor) { nil }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:board_id) { "123456" }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }
      let(:test_data) { create_test_board_with_items(client, board_name: "Pagination Test Board", item_count: 12) }
      let(:board_id) { test_data[:board_id] }

      after do
        safely_delete_board(client, board_id)
      end

      it_behaves_like "authenticated client request"

      it "returns items_page structure with cursor and items" do
        items_page = response.body.dig("data", "boards", 0, "items_page")

        expect(items_page).to include("cursor", "items")
      end

      it "returns the requested number of items" do
        items = response.body.dig("data", "boards", 0, "items_page", "items")

        expect(items.length).to eq(limit)
      end

      it "returns items with default fields (id, name)" do
        items = response.body.dig("data", "boards", 0, "items_page", "items")

        expect(items.first).to include("id", "name")
      end

      context "when using cursor for pagination" do
        let(:first_page) { client.board.items_page(board_ids: board_id, limit: 5) }
        let(:cursor) { first_page.body.dig("data", "boards", 0, "items_page", "cursor") }

        it "returns the next page of items" do
          first_page_items = first_page.body.dig("data", "boards", 0, "items_page", "items")
          first_page_ids = first_page_items.map { |item| item["id"] }

          second_page_items = response.body.dig("data", "boards", 0, "items_page", "items")
          second_page_ids = second_page_items.map { |item| item["id"] }

          expect(first_page_ids & second_page_ids).to be_empty
        end

        it "returns a cursor for the next page if more items exist" do
          cursor_value = response.body.dig("data", "boards", 0, "items_page", "cursor")

          expect(cursor_value).not_to be_nil
        end
      end

      context "when requesting custom select fields" do
        subject(:response) do
          client.board.items_page(
            board_ids: board_id,
            limit: 3,
            select: %w[id name state created_at]
          )
        end

        it "returns items with requested fields" do
          items = response.body.dig("data", "boards", 0, "items_page", "items")

          expect(items.first).to include("id", "name", "state", "created_at")
        end
      end

      context "when using query_params to filter items" do
        subject(:response) do
          client.board.items_page(
            board_ids: board_id,
            limit: 10,
            query_params: {
              rules: [{ column_id: "name", compare_value: ["Test Item 1"] }],
              operator: :and
            }
          )
        end

        it "returns filtered items based on query_params" do
          items = response.body.dig("data", "boards", 0, "items_page", "items")

          expect(items).to be_an(Array)
        end
      end

      context "when board_ids is an array" do
        subject(:response) do
          client.board.items_page(board_ids: [board_id], limit: 10)
        end

        it "accepts board_ids as an array and returns items" do
          boards = response.body.dig("data", "boards")

          expect(boards).to be_an(Array)
          expect(boards.first["items_page"]).to include("cursor", "items")
        end
      end

      context "when the board has no items" do
        let(:empty_board_data) { create_test_board_with_items(client, board_name: "Empty Board", item_count: 0) }
        let(:board_id) { empty_board_data[:board_id] }

        it "returns empty items array" do
          items = response.body.dig("data", "boards", 0, "items_page", "items")

          expect(items).to be_empty
        end

        it "returns nil cursor when no items exist" do
          cursor_value = response.body.dig("data", "boards", 0, "items_page", "cursor")

          expect(cursor_value).to be_nil
        end
      end
    end
  end
end
