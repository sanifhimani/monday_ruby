# frozen_string_literal: true

RSpec.describe Monday::Resources::File, :vcr do
  let(:create_board) do
    client.board.create(args: { board_name: "Test Board", board_kind: :private })
  end
  let(:board_id) { create_board.body["data"]["create_board"]["id"] }
  let(:create_column) do
    client.column.create(
      args: {
        board_id: board_id,
        title: "Files",
        description: "Documents",
        column_type: :file
      }
    )
  end
  let(:create_item) do
    client.item.create(
      args: {
        board_id: board_id,
        item_name: "Test Item"
      }
    )
  end
  let(:item_id) { create_item.body["data"]["create_item"]["id"] }
  let(:column_id) { create_column.body["data"]["create_column"]["id"] }
  let(:create_update) do
    client.update.create(
      args: {
        item_id: item_id,
        body: "This update will be added to the item"
      }
    )
  end
  let(:update_id) { create_update.body["data"]["create_update"]["id"] }
  let(:file) do
    UploadIO.new(
      File.open("spec/test_files/polarBear.jpg"),
      "image/jpeg",
      "polarBear.jpg"
    )
  end

  describe ".add_file_to_column" do
    subject(:response) { client.file.add_file_to_column(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      after do
        safely_delete_board(client, board_id)
      end

      context "when the item does not exist" do
        let(:args) do
          {
            item_id: item_id,
            column_id: column_id,
            file: file
          }
        end
        let(:item_id) { "123" }
        let(:column_id) { "file_123xyz" }
        let(:file) { "some_file_string" }

        it "raises Monday::InternalServerError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end

      context "when the args are invalid" do
        let(:args) do
          {
            item_id: item_id,
            column_id: column_id,
            file: "some_file_string" # Invalid file/stream
          }
        end
        let(:file) { "some_file_string" }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when the args are valid" do
        let(:args) do
          {
            item_id: item_id,
            column_id: column_id,
            file: file
          }
        end

        it_behaves_like "authenticated client request"

        it "returns the body with the ID, title and description of the created column" do
          expect(
            response.body["data"]["add_file_to_column"]
          ).to match(hash_including("id"))
        end
      end
    end
  end

  describe ".add_file_to_update" do
    subject(:response) { client.file.add_file_to_update(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      after do
        safely_delete_board(client, board_id)
      end

      context "when the update_id does not exist" do
        let(:args) do
          {
            update_id: update_id,
            file: file
          }
        end
        let(:update_id) { "123" }
        let(:file) { "some_file_string" }

        it "raises Monday::InternalServerError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end

      context "when the args are invalid" do
        let(:args) do
          {
            update_id: update_id,
            file: file
          }
        end
        let(:file) { "some_file_string" }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when the args are valid" do
        let(:args) do
          {
            update_id: update_id,
            file: file
          }
        end

        it_behaves_like "authenticated client request"

        it "returns the body with the ID, title and description of the created column" do
          expect(
            response.body["data"]["add_file_to_update"]
          ).to match(hash_including("id"))
        end
      end
    end
  end

  describe ".clear_file_column" do
    subject(:response) { client.file.clear_file_column(args: args) }

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
            column_id: column_id
          }
        end
        let(:board_id) { "123" }
        let(:item_id) { "123" }
        let(:column_id) { "file_123xyz" }

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
            column_id: column_id
          }
        end
        let(:item_id) { "123" }
        let(:column_id) { "file_123xyz" }

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
        let(:args) do
          {
            board_id: board_id,
            item_id: item_id,
            column_id: column_id
          }
        end

        after do
          safely_delete_board(client, board_id)
        end

        it_behaves_like "authenticated client request"

        it "returns the body with ID and name of the updated item" do
          expect(
            response.body["data"]["change_column_value"]
          ).to match(hash_including("id"))
        end
      end
    end
  end
end
