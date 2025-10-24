# frozen_string_literal: true

RSpec.describe Monday::Resources::Item, :vcr do
  describe ".query" do
    subject(:response) { client.item.query(args: args, select: select) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }
      let(:select) { %w[id name created_at] }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when an invalid field is requested" do
        let(:args) do
          {
            ids: item_id
          }
        end
        let(:select) { ["invalid_field"] }
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_item) do
          client.item.create(
            args: {
              board_id: board_id,
              item_name: "Test Item"
            }
          )
        end
        let(:item_id) { create_item.body["data"]["create_item"]["id"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when an item does not exist for the given item_id" do
        let(:args) do
          {
            ids: "123"
          }
        end
        let(:select) { %w[id name created_at] }

        it "returns an empty array" do
          expect(response.body["data"]["items"]).to eq([])
        end
      end

      context "when the args are valid" do
        let(:args) do
          {
            ids: item_id
          }
        end
        let(:select) { %w[id name created_at] }

        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_item) do
          client.item.create(
            args: {
              board_id: board_id,
              item_name: "Test Item"
            }
          )
        end
        let(:item_id) { create_item.body["data"]["create_item"]["id"] }

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
            board_id: board_id,
            item_name: "Test Item",
            column_values: {
              status__1: { # rubocop:disable Naming/VariableNumber
                label: "Done"
              }
            }
          }
        end
        let(:board_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidBoardIdException:/
          )
        end
      end

      context "when the args are valid" do
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

        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

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

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:board_id) { "123" }
      let(:item_id) { "123" }
      let(:with_updates) { true }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when the board does not exist for the given board_id" do
        let(:board_id) { "123" }
        let(:item_id) { "123" }
        let(:with_updates) { true }

        it "raises Monday::InternalServerError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end

      context "when the item does not exist for the given item_id" do
        let(:item_id) { "123" }
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let(:with_updates) { true }

        it "raises Monday::InternalServerError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end

      context "when the args are valid" do
        let(:with_updates) { true }

        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

        let!(:create_item) do
          client.item.create(
            args: {
              board_id: board_id,
              item_name: "Test Item"
            }
          )
        end
        let(:item_id) { create_item.body["data"]["create_item"]["id"] }

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
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

        let!(:create_item) do
          client.item.create(
            args: {
              board_id: board_id,
              item_name: "Test Item"
            }
          )
        end
        let(:item_id) { create_item.body["data"]["create_item"]["id"] }

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
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

        let!(:create_item) do
          client.item.create(
            args: {
              board_id: board_id,
              item_name: "Test Item"
            }
          )
        end
        let(:item_id) { create_item.body["data"]["create_item"]["id"] }

        it_behaves_like "authenticated client request"

        it "returns the body with the deleted item ID" do
          expect(
            response.body["data"]["delete_item"]
          ).to match(hash_including("id"))
        end
      end
    end
  end
end
