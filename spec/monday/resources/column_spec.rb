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

RSpec.describe Monday::Resources::Column, :vcr do
  describe ".columns" do
    subject(:response) { client.columns(select: select) }

    let(:select) { %w[id title description] }

    let(:query) { "query { boards() { columns {id title description}}}" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with column ID, title and description" do
        expect(
          response.body["data"]["boards"].first["columns"]
        ).to match(array_including(hash_including("id", "title", "description")))
      end

      context "when a field that doesn't exist on columns is requested" do
        let(:select) { ["invalid_field"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end
    end
  end

  describe ".column_values" do
    subject(:response) { client.column_values }

    let(:query) { "query { boards () { items () { column_values {id title description}}}}" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with columns values of items" do
        expect(
          response.body["data"]["boards"].first["items"]
        ).to match(array_including(hash_including("column_values")))
      end
    end
  end

  describe ".create_column" do
    subject(:response) { client.create_column(args: args) }

    let(:query) do
      "mutation { create_column(board_id: #{board_id}, title: Status, description: \"Status Column\", " \
        "column_type: text) {id title description}}"
    end

    let(:args) do
      {
        board_id: board_id,
        title: "Status",
        description: "Status Column",
        column_type: "text"
      }
    end

    let(:board_id) { "4751837459" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with columns values of items" do
        expect(
          response.body["data"]["create_column"]
        ).to match(hash_including("id", "title", "description"))
      end

      context "when the board does not exist for the given board_id" do
        let(:board_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidBoardIdException:/
          )
        end
      end

      context "when an invalid argument is passed" do
        let(:board_id) { "4751809923" }

        let(:args) do
          {
            board_id: board_id,
            title: "Status",
            description: "Status Column",
            column_type: "text",
            invalid_arg: "test"
          }
        end

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end
    end
  end

  describe ".change_column_title" do
    subject(:response) { client.change_column_title(args: args) }

    let(:query) do
      "mutation { change_column_title(board_id: #{board_id}, column_id: status, title: \"New status\") " \
        "{id title description}}"
    end

    let(:args) do
      {
        board_id: board_id,
        column_id: "status",
        title: "New status"
      }
    end

    let(:board_id) { "4751837459" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with columns values of items" do
        expect(
          response.body["data"]["change_column_title"]
        ).to match(hash_including("id", "title", "description"))
      end

      context "when the board does not exist for the given board_id" do
        let(:board_id) { "123" }

        it "raises Monday::InternalServerError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end
    end
  end

  describe ".change_column_metadata" do
    subject(:response) { client.change_column_metadata(args: args) }

    let(:query) do
      "mutation { change_column_metadata(board_id: #{board_id}, column_id: status, " \
        "column_property: description, value: \"New status description\") " \
        "{id title description}}"
    end

    let(:args) do
      {
        board_id: board_id,
        column_id: "status",
        column_property: "description",
        value: "New status description"
      }
    end

    let(:board_id) { "4751837459" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with columns values of items" do
        expect(
          response.body["data"]["change_column_metadata"]
        ).to match(hash_including("id", "title", "description"))
      end

      context "when the board does not exist for the given board_id" do
        let(:board_id) { "123" }

        it "raises Monday::InternalServerError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end
    end
  end

  describe ".change_column_value" do
    subject(:response) { client.change_column_value(args: args) }

    let(:query) do
      "mutation { change_column_value(board_id: #{board_id}, item_id: #{item_id}, " \
        "column_id: status8, value: \"{\\\"label\\\":\\\"Working on it\\\"}\") {id name}}"
    end

    let(:args) do
      {
        board_id: board_id,
        item_id: item_id,
        column_id: "status8",
        value: {
          label: "Working on it"
        }
      }
    end

    let(:board_id) { "4751837459" }
    let(:item_id) { "4751837477" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with ID and name of the updated item" do
        expect(
          response.body["data"]["change_column_value"]
        ).to match(hash_including("id", "name"))
      end

      context "when the board does not exist for the given board_id" do
        let(:board_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidBoardIdException:/
          )
        end
      end

      context "when the item does not exist for the given item_id" do
        let(:board_id) { "4751809923" }
        let(:item_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidItemIdException:/
          )
        end
      end
    end
  end

  describe ".change_simple_column_value" do
    subject(:response) { client.change_simple_column_value(args: args) }

    let(:query) do
      "mutation { change_simple_column_value(board_id: #{board_id}, item_id: #{item_id}, " \
        "column_id: status8, value: \"Stuck\") {id name}}"
    end

    let(:args) do
      {
        board_id: board_id,
        item_id: item_id,
        column_id: "status8",
        value: "Stuck"
      }
    end

    let(:board_id) { "4751837459" }
    let(:item_id) { "4751837477" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with ID and name of the updated item" do
        expect(
          response.body["data"]["change_simple_column_value"]
        ).to match(hash_including("id", "name"))
      end

      context "when the board does not exist for the given board_id" do
        let(:board_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidBoardIdException:/
          )
        end
      end

      context "when the item does not exist for the given item_id" do
        let(:board_id) { "4751809923" }
        let(:item_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidItemIdException:/
          )
        end
      end
    end
  end

  describe ".change_multiple_column_value" do
    subject(:response) { client.change_multiple_column_value(args: args) }

    let(:query) do
      "mutation { change_multiple_column_values(board_id: #{board_id}, item_id: #{item_id}, " \
        "column_values: \"{\\\"status\\\":\\\"Hello World\\\"," \
        "\\\"status8\\\":{\\\"label\\\":\\\"Working on it\\\"}}\") {id name}}"
    end

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

    let(:board_id) { "4751837459" }
    let(:item_id) { "4751837477" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with ID and name of the updated item" do
        expect(
          response.body["data"]["change_multiple_column_values"]
        ).to match(hash_including("id", "name"))
      end

      context "when the board does not exist for the given board_id" do
        let(:board_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidBoardIdException:/
          )
        end
      end

      context "when the item does not exist for the given item_id" do
        let(:board_id) { "4751809923" }
        let(:item_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidItemIdException:/
          )
        end
      end

      context "when incorrect column values are given" do
        let(:board_id) { "4691485686" }
        let(:item_id) { "4691485763" }

        let(:args) do
          {
            board_id: board_id,
            item_id: item_id,
            column_values: {
              status: {
                labels: ["Working on it"]
              }
            }
          }
        end

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /ColumnValueException:/
          )
        end
      end
    end
  end

  describe ".delete_column" do
    subject(:response) { client.delete_column(board_id, column_id) }

    let(:query) do
      "mutation { delete_column(board_id: #{board_id}, column_id: status) {id}}"
    end

    let(:board_id) { "4751837459" }
    let(:column_id) { "text" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it "returns the body with the deleted columns ID" do
        expect(
          response.body["data"]["delete_column"]
        ).to match(hash_including("id"))
      end

      context "when the board does not exist for the given board_id" do
        let(:board_id) { "123" }

        it "raises Monday::InternalServerError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end

      context "when the column does not exist for the given column_id" do
        let(:column_id) { "invalid_column" }

        it "raises Monday::AuthorizationError error" do
          expect { response }.to raise_error(Monday::AuthorizationError)
        end
      end
    end
  end
end
