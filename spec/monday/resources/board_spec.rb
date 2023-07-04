# frozen_string_literal: true

RSpec.shared_examples "unauthenticated client request" do
  it "returns 401 status" do
    expect(response.status).to eq(401)
  end
end

RSpec.shared_examples "authenticated client request" do
  it "returns 200 status" do
    expect(response.status).to eq(200)
  end
end

RSpec.describe Monday::Resources::Board, :vcr do
  let(:uri) { URI.parse(monday_url) }
  let(:body) do
    {
      query: query
    }
  end

  describe ".boards" do
    subject(:response) { client.boards }

    let(:query) { "query { boards() {id name description}}" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with ID, name and description" do
        expect(
          response.body["data"]["boards"]
        ).to match(array_including(hash_including("id", "name", "description")))
      end
    end
  end

  describe ".create_board" do
    subject(:response) { client.create_board(args: args) }

    let(:query) do
      "mutation { create_board(board_name: \"New test board\", board_kind: private) {id name description}}"
    end

    let(:args) do
      {
        board_name: "New test board",
        board_kind: "private"
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with created boards ID, name and description" do
        expect(
          response.body["data"]["create_board"]
        ).to match(hash_including("id", "name", "description"))
      end
    end
  end

  describe ".duplicate_board" do
    subject(:response) { client.duplicate_board(args: args) }

    let(:query) do
      "mutation { duplicate_board(board_id: #{board_id}, duplicate_type: duplicate_board_with_structure) " \
        "{ board {id name description}}}"
    end

    let(:args) do
      {
        board_id: board_id,
        duplicate_type: "duplicate_board_with_structure"
      }
    end

    let(:board_id) { "4751686616" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with duplicated boards ID, name and description" do
        expect(
          response.body["data"]["duplicate_board"]["board"]
        ).to match(hash_including("id", "name", "description"))
      end
    end
  end

  describe ".update_board" do
    subject(:response) { client.update_board(args: args) }

    let(:query) do
      "mutation { update_board(board_id: #{board_id}, board_attribute: description, new_value: \"New description\")}"
    end

    let(:board_id) { "4751845443" }

    let(:args) do
      {
        board_id: board_id,
        board_attribute: "description",
        new_value: "New description"
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with update status and undo data" do
        expect(
          JSON.parse(response.body["data"]["update_board"])
        ).to match(hash_including("success", "undo_data"))
      end
    end
  end

  describe ".archive_board" do
    subject(:response) { client.archive_board(board_id) }

    let(:query) do
      "mutation { archive_board(board_id: #{board_id}) {id}}"
    end

    let(:board_id) { "4751845270" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it "returns the body with archived boards ID" do
        expect(
          response.body["data"]["archive_board"]
        ).to match(hash_including("id"))
      end
    end
  end

  describe ".delete_board" do
    subject(:response) { client.delete_board(board_id) }

    let(:query) do
      "mutation { delete_board(board_id: #{board_id}) {id}}"
    end

    let(:board_id) { "4751845270" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it "returns the body with deleted boards ID" do
        expect(
          response.body["data"]["delete_board"]
        ).to match(hash_including("id"))
      end
    end
  end

  describe ".delete_board_subscribers" do
    subject(:response) { client.delete_board_subscribers(board_id, user_ids) }

    let(:query) do
      "mutation { delete_subscribers_from_board(board_id: #{board_id}, user_ids: #{user_ids}) {id}}"
    end

    let(:board_id) { "4751787329" }
    let(:user_ids) { [44_865_791] }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it "returns the body with deleted boards ID" do
        expect(
          response.body["data"]["delete_subscribers_from_board"]
        ).to match(array_including(hash_including("id")))
      end
    end
  end
end
