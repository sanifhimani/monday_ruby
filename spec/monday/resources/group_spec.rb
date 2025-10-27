# frozen_string_literal: true

RSpec.describe Monday::Resources::Group, :vcr do
  describe ".query" do
    subject(:response) { client.group.query(select: select) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:select) { %w[id title] }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when an invalid field is requested" do
        let(:select) { ["invalid_field"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when valid fields are requested" do
        let(:select) { %w[id title] }

        it_behaves_like "authenticated client request"

        it "returns the body with ID and title" do
          expect(
            response.body["data"]["boards"].first["groups"]
          ).to match(array_including(hash_including("id", "title")))
        end
      end
    end
  end

  describe ".create" do
    subject(:response) { client.group.create(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }
      let(:test_data) { create_test_board_with_items(client, board_name: "Group Create Test Board", item_count: 0) }
      let(:board_id) { test_data[:board_id] }

      after do
        safely_delete_board(client, board_id)
      end

      context "when a field that doesn't exist on groups is given" do
        let(:args) do
          {
            board_id: board_id,
            group_name: "Returned orders",
            invalid_field: "test"
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
            group_name: "Returned orders"
          }
        end

        it_behaves_like "authenticated client request"

        it "returns the body with created groups ID and Title" do
          expect(
            response.body["data"]["create_group"]
          ).to match(hash_including("id", "title"))
        end
      end
    end
  end

  describe ".update" do
    subject(:response) { client.group.update(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when a the group with the given group ID does not exist" do
        let(:test_data) { create_test_board_with_items(client, board_name: "Update Test Board", item_count: 0) }
        let(:board_id) { test_data[:board_id] }
        let(:args) do
          {
            board_id: board_id,
            group_id: "dog",
            group_attribute: "title",
            new_value: "Voided orders"
          }
        end

        after do
          safely_delete_board(client, board_id)
        end

        it "raises Monday::Error error" do
          # This throws an ActiveRecord error on the Monday API side.
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when args are invalid" do
        let(:test_data) do
          create_test_board_with_group_and_items(client, board_name: "Update Invalid Test", group_name: "Test Group",
                                                         item_count: 0)
        end
        let(:board_id) { test_data[:board_id] }
        let(:group_id) { test_data[:group_id] }
        let(:args) do
          {
            board_id: board_id,
            group_id: group_id,
            group_attribute: "title",
            new_value: "Voided orders"
          }
        end

        after do
          safely_delete_board(client, board_id)
        end

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when args are valid" do
        let(:test_data) do
          create_test_board_with_group_and_items(client, board_name: "Update Valid Test", group_name: "Test Group",
                                                         item_count: 0)
        end
        let(:board_id) { test_data[:board_id] }
        let(:group_id) { test_data[:group_id] }
        let(:args) do
          {
            board_id: board_id,
            group_id: group_id,
            group_attribute: :title,
            new_value: "Voided orders"
          }
        end

        after do
          safely_delete_board(client, board_id)
        end

        it_behaves_like "authenticated client request"

        it "returns the body with updated groups ID" do
          expect(
            response.body["data"]["update_group"]
          ).to match(hash_including("id"))
        end
      end
    end
  end

  describe ".duplicate" do
    subject(:response) { client.group.duplicate(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when a the group with the given group ID does not exist" do
        let(:test_data) { create_test_board_with_items(client, board_name: "Duplicate Test Board", item_count: 0) }
        let(:board_id) { test_data[:board_id] }
        let(:args) do
          {
            board_id: board_id,
            group_id: "invalid_group_name"
          }
        end

        after do
          safely_delete_board(client, board_id)
        end

        it "raises Monday::ResourceNotFoundError error" do
          expect { response }.to raise_error(Monday::ResourceNotFoundError)
        end
      end

      context "when the board with the given board ID does not exist" do
        let(:args) do
          {
            board_id: "invalid_board_name",
            group_id: "invalid_group_name"
          }
        end

        it "raises Monday::InternalServerError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end

      context "when the args are valid" do
        let(:test_data) do
          create_test_board_with_group_and_items(client, board_name: "Duplicate Valid Test", group_name: "Test Group",
                                                         item_count: 0)
        end
        let(:board_id) { test_data[:board_id] }
        let(:group_id) { test_data[:group_id] }
        let(:args) do
          {
            board_id: board_id,
            group_id: group_id
          }
        end

        after do
          safely_delete_board(client, board_id)
        end

        it_behaves_like "authenticated client request"

        it "returns the body with duplicated groups ID and Title" do
          expect(
            response.body["data"]["duplicate_group"]
          ).to match(hash_including("id", "title"))
        end
      end
    end
  end

  describe ".archive" do
    subject(:response) { client.group.archive(args: { board_id: board_id, group_id: group_id }) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:board_id) { "123" }
      let(:group_id) { "123" }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when a the group with the given group ID does not exist" do
        let(:test_data) { create_test_board_with_items(client, board_name: "Archive Test Board", item_count: 0) }
        let(:board_id) { test_data[:board_id] }
        let(:group_id) { "invalid_group_id" }

        after do
          safely_delete_board(client, board_id)
        end

        it "raises Monday::AuthorizationError error" do
          expect { response }.to raise_error(Monday::AuthorizationError)
        end
      end

      context "when the board with the given board ID does not exist" do
        let(:board_id) { "invalid_board_id" }
        let(:group_id) { "invalid_group_id" }

        it "raises Monday::InternalServerError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end

      context "when the args are valid" do
        let(:test_data) do
          create_test_board_with_group_and_items(client, board_name: "Archive Valid Test", group_name: "Test Group",
                                                         item_count: 0)
        end
        let(:board_id) { test_data[:board_id] }
        let(:group_id) { test_data[:group_id] }

        after do
          safely_delete_board(client, board_id)
        end

        it_behaves_like "authenticated client request"

        it "returns the body with archived groups ID" do
          expect(
            response.body["data"]["archive_group"]
          ).to match(hash_including("id"))
        end
      end
    end
  end

  describe ".delete" do
    subject(:response) { client.group.delete(args: { board_id: board_id, group_id: group_id }) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:board_id) { "123" }
      let(:group_id) { "123" }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when a the group with the given group ID does not exist" do
        let(:test_data) { create_test_board_with_items(client, board_name: "Delete Test Board", item_count: 0) }
        let(:board_id) { test_data[:board_id] }
        let(:group_id) { "invalid_group_name" }

        after do
          safely_delete_board(client, board_id)
        end

        it "raises Monday::AuthorizationError error" do
          expect { response }.to raise_error(Monday::AuthorizationError)
        end
      end

      context "when the board with the given board ID does not exist" do
        let(:board_id) { "invalid_board_name" }
        let(:group_id) { "invalid_group_name" }

        it "raises Monday::InternalServerError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end

      context "when the args are valid" do
        let(:test_data) do
          create_test_board_with_group_and_items(client, board_name: "Delete Valid Test", group_name: "Test Group",
                                                         item_count: 0)
        end
        let(:board_id) { test_data[:board_id] }
        let(:group_id) { test_data[:group_id] }

        after do
          safely_delete_board(client, board_id)
        end

        it_behaves_like "authenticated client request"

        it "returns the body with deleted groups ID" do
          expect(
            response.body["data"]["delete_group"]
          ).to match(hash_including("id"))
        end
      end
    end
  end

  describe ".move_item" do
    subject(:response) { client.group.move_item(args: { item_id: item_id, group_id: group_id }) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:item_id) { "123" }
      let(:group_id) { "123" }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when a the group with the given group ID does not exist" do
        let(:test_data) do
          create_test_board_with_group_and_items(client, board_name: "Move Item Test", group_name: "Test Group",
                                                         item_count: 1)
        end
        let(:board_id) { test_data[:board_id] }
        let(:item_id) { test_data[:item_ids].first }
        let(:group_id) { "invalid_group_id" }

        after do
          safely_delete_board(client, board_id)
        end

        it "raises Monday::ResourceNotFoundError error" do
          expect { response }.to raise_error(Monday::ResourceNotFoundError)
        end
      end

      context "when the item with the given item ID does not exist" do
        let(:test_data) do
          create_test_board_with_group_and_items(client, board_name: "Move Item Invalid Test",
                                                         group_name: "Test Group", item_count: 0)
        end
        let(:board_id) { test_data[:board_id] }
        let(:group_id) { test_data[:group_id] }
        let(:item_id) { "invalid_item_id" }

        after do
          safely_delete_board(client, board_id)
        end

        it "raises Monday::InternalServerError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end

      context "when the args are valid" do
        let(:test_data) do
          create_test_board_with_group_and_items(client, board_name: "Move Item Valid Test", group_name: "Test Group",
                                                         item_count: 1)
        end
        let(:board_id) { test_data[:board_id] }
        let(:group_id) { test_data[:group_id] }
        let(:item_id) { test_data[:item_ids].first }

        after do
          safely_delete_board(client, board_id)
        end

        it_behaves_like "authenticated client request"

        it "returns the body with moved items ID" do
          expect(
            response.body["data"]["move_item_to_group"]
          ).to match(hash_including("id"))
        end
      end
    end
  end

  describe ".items_page" do
    subject(:response) do
      client.group.items_page(board_ids: board_id, group_ids: group_id, limit: limit, cursor: cursor)
    end

    let(:limit) { 5 }
    let(:cursor) { nil }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:board_id) { "123456" }
      let(:group_id) { "group_123" }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }
      let(:test_data) do
        create_test_board_with_group_and_items(
          client,
          board_name: "Group Pagination Test Board",
          group_name: "Test Group",
          item_count: 12
        )
      end
      let(:board_id) { test_data[:board_id] }
      let(:group_id) { test_data[:group_id] }

      after do
        safely_delete_board(client, board_id)
      end

      it_behaves_like "authenticated client request"

      it "returns items_page structure with cursor and items" do
        items_page = response.body.dig("data", "boards", 0, "groups", 0, "items_page")

        expect(items_page).to include("cursor", "items")
      end

      it "returns the requested number of items" do
        items = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "items")

        expect(items.length).to eq(limit)
      end

      it "returns items with default fields (id, name)" do
        items = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "items")

        expect(items.first).to include("id", "name")
      end

      context "when using cursor for pagination" do
        let(:first_page) do
          client.group.items_page(board_ids: board_id, group_ids: group_id, limit: 5)
        end
        let(:cursor) { first_page.body.dig("data", "boards", 0, "groups", 0, "items_page", "cursor") }

        it "returns the next page of items" do
          first_page_items = first_page.body.dig("data", "boards", 0, "groups", 0, "items_page", "items")
          first_page_ids = first_page_items.map { |item| item["id"] }

          second_page_items = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "items")
          second_page_ids = second_page_items.map { |item| item["id"] }

          expect(first_page_ids & second_page_ids).to be_empty
        end

        it "returns a cursor for the next page if more items exist" do
          cursor_value = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "cursor")

          expect(cursor_value).not_to be_nil
        end
      end

      context "when requesting custom select fields" do
        subject(:response) do
          client.group.items_page(
            board_ids: board_id,
            group_ids: group_id,
            limit: 3,
            select: %w[id name state created_at]
          )
        end

        it "returns items with requested fields" do
          items = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "items")

          expect(items.first).to include("id", "name", "state", "created_at")
        end
      end

      context "when using query_params to filter items" do
        subject(:response) do
          client.group.items_page(
            board_ids: board_id,
            group_ids: group_id,
            limit: 10,
            query_params: {
              rules: [{ column_id: "name", compare_value: ["Test Item 1"] }],
              operator: :and
            }
          )
        end

        it "returns filtered items based on query_params" do
          items = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "items")

          expect(items).to be_an(Array)
        end
      end

      context "when board_ids is an array" do
        subject(:response) do
          client.group.items_page(board_ids: [board_id], group_ids: group_id, limit: 10)
        end

        it "returns boards as an array" do
          boards = response.body.dig("data", "boards")

          expect(boards).to be_an(Array)
        end

        it "returns items_page structure with cursor and items" do
          boards = response.body.dig("data", "boards")

          expect(boards.first["groups"].first["items_page"]).to include("cursor", "items")
        end
      end

      context "when group_ids is an array" do
        subject(:response) do
          client.group.items_page(board_ids: board_id, group_ids: [group_id], limit: 10)
        end

        it "returns groups as an array" do
          groups = response.body.dig("data", "boards", 0, "groups")

          expect(groups).to be_an(Array)
        end

        it "returns items_page structure with cursor and items" do
          groups = response.body.dig("data", "boards", 0, "groups")

          expect(groups.first["items_page"]).to include("cursor", "items")
        end
      end

      context "when the group has no items" do
        let(:empty_group_data) do
          create_test_board_with_group_and_items(
            client,
            board_name: "Empty Group Board",
            group_name: "Empty Group",
            item_count: 0
          )
        end
        let(:board_id) { empty_group_data[:board_id] }
        let(:group_id) { empty_group_data[:group_id] }

        it "returns empty items array" do
          items = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "items")

          expect(items).to be_empty
        end

        it "returns nil cursor when no items exist" do
          cursor_value = response.body.dig("data", "boards", 0, "groups", 0, "items_page", "cursor")

          expect(cursor_value).to be_nil
        end
      end
    end
  end
end
