# frozen_string_literal: true

RSpec.describe Monday::Resources::Update, :vcr do
  describe ".query" do
    subject(:response) { client.update.query(args: args, select: select) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }
      let(:select) { %w[id body created_at] }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when an invalid field is requested" do
        let(:args) do
          {
            limit: 10
          }
        end
        let(:select) { ["invalid_field"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when valid fields are requested" do
        let(:args) do
          {
            limit: 10
          }
        end
        let(:select) { %w[id body created_at] }

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

        before do
          client.update.create(args: { item_id: item_id, body: "This update will be added to the item" })
        end

        it_behaves_like "authenticated client request"

        it "returns the body with item ID, body and created_at" do
          expect(
            response.body["data"]["updates"]
          ).to match(array_including(hash_including("id", "body", "created_at")))
        end
      end
    end
  end

  describe ".create" do
    subject(:response) { client.update.create(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when the item does not exist for the given item ID" do
        let(:args) do
          {
            item_id: item_id,
            body: "This update will be added to the item"
          }
        end

        let(:item_id) { "123" }

        it "raises Monday::InternalServerError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end

      context "when the args are valid" do
        let(:args) do
          {
            item_id: item_id,
            body: "This update will be added to the item"
          }
        end

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

        it "returns the body with the created updates ID, body and created_at" do
          expect(
            response.body["data"]["create_update"]
          ).to match(hash_including("id", "body", "created_at"))
        end
      end
    end
  end

  describe ".like" do
    subject(:response) { client.update.like(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when the update_id does not exist" do
        let(:args) do
          {
            update_id: update_id
          }
        end

        let(:update_id) { "123" }

        it "raises Monday::AuthorizationError error" do
          expect { response }.to raise_error(Monday::AuthorizationError)
        end
      end

      context "when the args are valid" do
        let(:args) do
          {
            update_id: update_id
          }
        end

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

        let!(:create_update) do
          client.update.create(args: { item_id: item_id, body: "This update will be added to the item" })
        end
        let(:update_id) { create_update.body["data"]["create_update"]["id"] }

        it_behaves_like "authenticated client request"

        it "returns the body with the ID of the liked update" do
          expect(
            response.body["data"]["like_update"]
          ).to match(hash_including("id"))
        end
      end
    end
  end

  describe ".clear_item_updates" do
    subject(:response) { client.update.clear_item_updates(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when the item does not exist for the given item_id" do
        let(:args) do
          {
            item_id: item_id
          }
        end

        let(:item_id) { "123" }

        it "raises Monday::InternalServerError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end

      context "when the args are valid" do
        let(:args) do
          {
            item_id: item_id
          }
        end

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

        it "returns the body with the ID of the cleared update" do
          expect(
            response.body["data"]["clear_item_updates"]
          ).to match(hash_including("id"))
        end
      end
    end
  end

  describe ".delete" do
    subject(:response) { client.update.delete(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when the update does not exist for the given ID" do
        let(:args) do
          {
            id: update_id
          }
        end

        let(:update_id) { "123" }

        it "raises Monday::ResourceNotFoundError error" do
          expect { response }.to raise_error(Monday::ResourceNotFoundError)
        end
      end

      context "when the update exists" do
        let(:args) do
          {
            id: update_id
          }
        end

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

        let!(:create_update) do
          client.update.create(args: { item_id: item_id, body: "This update will be added to the item" })
        end
        let(:update_id) { create_update.body["data"]["create_update"]["id"] }

        it_behaves_like "authenticated client request"

        it "returns the body with the ID of the deleted update" do
          expect(
            response.body["data"]["delete_update"]
          ).to match(hash_including("id"))
        end
      end
    end
  end
end
