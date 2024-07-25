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

      context "when a field that doesn't exist on groups is given" do
        let(:args) do
          {
            board_id: board_id,
            group_name: "Returned orders",
            invalid_field: "test"
          }
        end
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

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
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

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
        let(:args) do
          {
            board_id: board_id,
            group_id: "dog",
            group_attribute: "title",
            new_value: "Voided orders"
          }
        end
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

        it "raises Monday::Error error" do
          # This throws an ActiveRecord error on the Monday API side.
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when args are invalid" do
        let(:args) do
          {
            board_id: board_id,
            group_id: group_id,
            group_attribute: "title",
            new_value: "Voided orders"
          }
        end
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_group) do
          client.group.create(args: { board_id: board_id, group_name: "Returned orders" })
        end
        let(:group_id) { create_group.body["data"]["create_group"]["id"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when args are valid" do
        let(:args) do
          {
            board_id: board_id,
            group_id: group_id,
            group_attribute: :title,
            new_value: "Voided orders"
          }
        end
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_group) do
          client.group.create(args: { board_id: board_id, group_name: "Returned orders" })
        end
        let(:group_id) { create_group.body["data"]["create_group"]["id"] }

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
        let(:args) do
          {
            board_id: board_id,
            group_id: "invalid_group_name"
          }
        end
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

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
        let(:args) do
          {
            board_id: board_id,
            group_id: group_id
          }
        end
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_group) do
          client.group.create(args: { board_id: board_id, group_name: "Returned orders" })
        end
        let(:group_id) { create_group.body["data"]["create_group"]["id"] }

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
        let(:group_id) { "invalid_group_id" }
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

        it "raises Monday::ResourceNotFoundError error" do
          expect { response }.to raise_error(Monday::ResourceNotFoundError)
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
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_group) do
          client.group.create(args: { board_id: board_id, group_name: "Returned orders" })
        end
        let(:group_id) { create_group.body["data"]["create_group"]["id"] }

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
        let(:group_id) { "invalid_group_name" }
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

        it "raises Monday::ResourceNotFoundError error" do
          expect { response }.to raise_error(Monday::ResourceNotFoundError)
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
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_group) do
          client.group.create(args: { board_id: board_id, group_name: "Returned orders" })
        end
        let(:group_id) { create_group.body["data"]["create_group"]["id"] }

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
        let(:group_id) { "invalid_group_id" }
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_item) do
          client.item.create(args: { board_id: board_id, item_name: "Test Item" })
        end
        let(:item_id) { create_item.body["data"]["create_item"]["id"] }

        it "raises Monday::ResourceNotFoundError error" do
          expect { response }.to raise_error(Monday::ResourceNotFoundError)
        end
      end

      context "when the item with the given item ID does not exist" do
        let(:item_id) { "invalid_item_id" }
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_group) do
          client.group.create(args: { board_id: board_id, group_name: "Returned orders" })
        end
        let(:group_id) { create_group.body["data"]["create_group"]["id"] }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidItemIdException/
          )
        end
      end

      context "when the args are valid" do
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_group) do
          client.group.create(args: { board_id: board_id, group_name: "Returned orders" })
        end
        let(:group_id) { create_group.body["data"]["create_group"]["id"] }
        let!(:create_item) do
          client.item.create(args: { board_id: board_id, item_name: "Test Item" })
        end
        let(:item_id) { create_item.body["data"]["create_item"]["id"] }

        it_behaves_like "authenticated client request"

        it "returns the body with moved items ID" do
          expect(
            response.body["data"]["move_item_to_group"]
          ).to match(hash_including("id"))
        end
      end
    end
  end
end
