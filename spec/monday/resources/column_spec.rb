# frozen_string_literal: true

RSpec.describe Monday::Resources::Column, :vcr do
  describe ".query" do
    subject(:response) { client.column.query(select: select) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:select) { %w[id title description] }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      let!(:create_board) do
        client.board.create(args: { board_name: "Test Board", board_kind: :private })
      end
      let(:board_id) { create_board.body["data"]["create_board"]["id"] }

      before do
        client.column.create(
          args: {
            board_id: board_id,
            title: "Test Column",
            column_type: :text
          }
        )
      end

      context "when invalid field is requested" do
        let(:select) { ["invalid_field"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when valid field is requested" do
        let(:select) { %w[id title description] }

        it_behaves_like "authenticated client request"

        it "returns the body with column ID, title and description" do
          expect(
            response.body["data"]["boards"].first["columns"]
          ).to match(array_including(hash_including("id", "title", "description")))
        end
      end
    end
  end

  describe ".create" do
    subject(:response) { client.column.create(args: args) }

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
            title: "Status",
            description: "Status Column",
            column_type: :status
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

      context "when the args are invalid" do
        let(:args) do
          {
            board_id: board_id,
            title: "Status",
            description: "Status Column",
            column_type: "status"
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

      context "when the args are valid" do
        let(:args) do
          {
            board_id: board_id,
            title: "Status",
            description: "Status Column",
            column_type: :status
          }
        end

        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

        it_behaves_like "authenticated client request"

        it "returns the body with the ID, title and description of the created column" do
          expect(
            response.body["data"]["create_column"]
          ).to match(hash_including("id", "title", "description"))
        end
      end
    end
  end

  describe ".change_title" do
    subject(:response) { client.column.change_title(args: args) }

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
            column_id: "status",
            title: "New status"
          }
        end
        let(:board_id) { "123" }

        it "raises Monday::InternalServerError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end

      context "when the args are valid" do
        let(:args) do
          {
            board_id: board_id,
            column_id: "test_column__1",
            title: "New title"
          }
        end
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_column) do
          client.column.create(
            args: {
              board_id: board_id,
              title: "Test Column",
              column_type: :text
            }
          )
        end

        it_behaves_like "authenticated client request"

        it "returns the body with the ID, title and description of the updated column" do
          expect(
            response.body["data"]["change_column_title"]
          ).to match(hash_including("id", "title", "description"))
        end
      end
    end
  end

  describe ".change_metadata" do
    subject(:response) { client.column.change_metadata(args: args) }

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
            column_id: "status",
            column_property: :description,
            value: "New status description"
          }
        end
        let(:board_id) { "123" }

        it "raises Monday::InternalServerError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end

      context "when the args are invalid" do
        let(:args) do
          {
            board_id: board_id,
            column_id: "test_column__1",
            column_property: "description",
            value: "New description"
          }
        end
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_column) do
          client.column.create(
            args: {
              board_id: board_id,
              title: "Test Column",
              column_type: :text
            }
          )
        end

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when the args are valid" do
        let(:args) do
          {
            board_id: board_id,
            column_id: "test_column__1",
            column_property: :description,
            value: "New description"
          }
        end
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_column) do
          client.column.create(
            args: {
              board_id: board_id,
              title: "Test Column",
              column_type: :text
            }
          )
        end

        it_behaves_like "authenticated client request"

        it "returns the body with the ID, title and description of the updated column" do
          expect(
            response.body["data"]["change_column_metadata"]
          ).to match(hash_including("id", "title", "description"))
        end
      end
    end
  end

  describe ".change_value" do
    subject(:response) { client.column.change_value(args: args) }

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
            item_id: item_id,
            column_id: "status",
            value: {
              label: "Working on it"
            }
          }
        end
        let(:board_id) { "123" }
        let(:item_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidBoardIdException:/
          )
        end
      end

      context "when the item does not exist for the given item_id" do
        let(:args) do
          {
            board_id: board_id,
            item_id: item_id,
            column_id: "status",
            value: {
              label: "Working on it"
            }
          }
        end
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let(:item_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidItemIdException:/
          )
        end
      end

      context "when the args are valid" do
        let(:args) do
          {
            board_id: board_id,
            item_id: item_id,
            column_id: "status__1",
            value: {
              label: "Working on it"
            }
          }
        end
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_column) do
          client.column.create(
            args: {
              board_id: board_id,
              title: "Status",
              description: "Status Column",
              column_type: :status
            }
          )
        end
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

        it "returns the body with ID and name of the updated item" do
          expect(
            response.body["data"]["change_column_value"]
          ).to match(hash_including("id", "name"))
        end
      end
    end
  end

  describe ".change_simple_value" do
    subject(:response) { client.column.change_simple_value(args: args) }

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
            item_id: item_id,
            column_id: "status",
            value: "Working on it"
          }
        end
        let(:board_id) { "123" }
        let(:item_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidBoardIdException:/
          )
        end
      end

      context "when the item does not exist for the given item_id" do
        let(:args) do
          {
            board_id: board_id,
            item_id: item_id,
            column_id: "status",
            value: "Working on it"
          }
        end
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let(:item_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidItemIdException:/
          )
        end
      end

      context "when the args are valid" do
        let(:args) do
          {
            board_id: board_id,
            item_id: item_id,
            column_id: "status__1",
            value: "Working on it"
          }
        end
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_column) do
          client.column.create(
            args: {
              board_id: board_id,
              title: "Status",
              description: "Status Column",
              column_type: :status
            }
          )
        end
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

        it "returns the body with ID and name of the updated item" do
          expect(
            response.body["data"]["change_simple_column_value"]
          ).to match(hash_including("id", "name"))
        end
      end
    end
  end

  describe ".change_multiple_values" do
    subject(:response) { client.column.change_multiple_values(args: args) }

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
            item_id: item_id,
            column_values: {
              status: "Hello World",
              status8: {
                label: "Done"
              }
            }
          }
        end
        let(:board_id) { "123" }
        let(:item_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidBoardIdException:/
          )
        end
      end

      context "when the item does not exist for the given item_id" do
        let(:args) do
          {
            board_id: board_id,
            item_id: item_id,
            column_values: {
              status: "Hello World",
              status8: {
                label: "Done"
              }
            }
          }
        end
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let(:item_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidItemIdException:/
          )
        end
      end

      context "when the column values are invalid" do
        let(:args) do
          {
            board_id: board_id,
            item_id: item_id,
            column_values: {
              status: "Hello World",
              status8: {
                label: "Done"
              }
            }
          }
        end
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_column) do
          client.column.create(
            args: {
              board_id: board_id,
              title: "Status",
              description: "Status Column",
              column_type: :status
            }
          )
        end
        let!(:create_item) do
          client.item.create(
            args: {
              board_id: board_id,
              item_name: "Test Item"
            }
          )
        end
        let(:item_id) { create_item.body["data"]["create_item"]["id"] }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidColumnIdException:/
          )
        end
      end

      context "when the args are valid" do
        let(:args) do
          {
            board_id: board_id,
            item_id: item_id,
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
        let!(:create_column) do
          client.column.create(
            args: {
              board_id: board_id,
              title: "Status",
              description: "Status Column",
              column_type: :status
            }
          )
        end
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

        it "returns the body with ID and name of the updated item" do
          expect(
            response.body["data"]["change_multiple_column_values"]
          ).to match(hash_including("id", "name"))
        end
      end
    end
  end

  describe ".delete" do
    subject(:response) { client.column.delete(board_id, column_id) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:board_id) { "123" }
      let(:column_id) { "status" }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when the board does not exist for the given board_id" do
        let(:board_id) { "123" }
        let(:column_id) { "status" }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when the column does not exist for the given column_id" do
        let(:board_id) { "123" }
        let(:column_id) { "invalid_column" }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when the args are valid" do
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }
        let!(:create_column) do
          client.column.create(
            args: {
              board_id: board_id,
              title: "Status",
              description: "Status Column",
              column_type: :status
            }
          )
        end
        let(:column_id) { create_column.body["data"]["create_column"]["id"] }

        it_behaves_like "authenticated client request"

        it "returns the body with the deleted columns ID" do
          expect(
            response.body["data"]["delete_column"]
          ).to match(hash_including("id"))
        end
      end
    end
  end
end
