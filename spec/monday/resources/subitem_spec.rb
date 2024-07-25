# frozen_string_literal: true

RSpec.shared_examples "unauthenticated client request" do
  it "raises Monday::AuthorizationError error" do
    expect { response }.to raise_error(Monday::AuthorizationError)
  end
end

RSpec.shared_examples "authenticated client request" do
  it "returns 200 status" do
    expect(response.status).to eq(200)
  end
end

RSpec.describe Monday::Resources::Subitem, :vcr do
  describe ".query" do
    subject(:response) { client.subitem.query(args: args, select: select) }

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
            ids: item_id
          }
        end
        let(:select) { ["invalid_field"] }

        let(:item_id) { "123" }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
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

        before do
          client.subitem.create(
            args: {
              parent_item_id: item_id,
              item_name: "New Item Test"
            }
          )
        end

        it_behaves_like "authenticated client request"

        it "returns the body with ID, name and created_at fields of the subitems" do
          expect(
            response.body["data"]["items"].first["subitems"]
          ).to match(array_including(hash_including("id", "name", "created_at")))
        end
      end
    end
  end

  describe ".create" do
    subject(:response) { client.subitem.create(args: args) }

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
            parent_item_id: item_id,
            item_name: "New Item Test"
          }
        end

        let(:item_id) { "123" }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when the args are valid" do
        let(:args) do
          {
            parent_item_id: item_id,
            item_name: "New Item Test"
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

        it "returns the body with ID, name and created_at fields of the created subitem" do
          expect(
            response.body["data"]["create_subitem"]
          ).to match(hash_including("id", "name", "created_at"))
        end
      end
    end
  end
end
