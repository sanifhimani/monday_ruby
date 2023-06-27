# frozen_string_literal: true

RSpec.shared_examples "unauthenticated client request" do
  before do
    stub_request(:post, uri)
      .with(body: body.to_json)
      .to_return(status: 401, body: fixture("unauthenticated.json"))
  end

  it "returns 401 status" do
    expect(response.status).to eq(401)
  end
end

RSpec.shared_examples "authenticated client request" do |fixture|
  before do
    stub_request(:post, uri)
      .with(body: body.to_json)
      .to_return(status: 200, body: fixture(fixture))
  end

  it "returns 200 status" do
    expect(response.status).to eq(200)
  end
end

RSpec.describe Monday::Resources::Board do
  let(:uri) { URI.parse(monday_url) }
  let(:body) do
    {
      query: query
    }
  end

  let(:invalid_client) do
    Monday::Client.new(token: nil)
  end

  let(:valid_client) do
    Monday::Client.new(token: "xxx")
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

      it_behaves_like "authenticated client request", "board/boards.json"
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

      it_behaves_like "authenticated client request", "board/create_board.json"
    end
  end

  describe ".duplicate_board" do
    subject(:response) { client.duplicate_board(args: args) }

    let(:query) do
      "mutation { duplicate_board(board_id: 456, duplicate_type: duplicate_board_with_structure) " \
        "{ board {id name description}}}"
    end

    let(:args) do
      {
        board_id: 456,
        duplicate_type: "duplicate_board_with_structure"
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "board/duplicate_board.json"
    end
  end

  describe ".update_board" do
    subject(:response) { client.update_board(args: args) }

    let(:query) do
      "mutation { update_board(board_id: 789, board_attribute: description, new_value: \"New description\")}"
    end

    let(:args) do
      {
        board_id: 789,
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

      it_behaves_like "authenticated client request", "board/update_board.json"
    end
  end

  describe ".archive_board" do
    subject(:response) { client.archive_board(789) }

    let(:query) do
      "mutation { archive_board(board_id: 789) {id}}"
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "board/archive_board.json"
    end
  end

  describe ".delete_board" do
    subject(:response) { client.delete_board(789) }

    let(:query) do
      "mutation { delete_board(board_id: 789) {id}}"
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "board/delete_board.json"
    end
  end

  describe ".delete_board_subscribers" do
    subject(:response) { client.delete_board_subscribers(789, [123]) }

    let(:query) do
      "mutation { delete_subscribers_from_board(board_id: 789, user_ids: [123]) {id}}"
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "board/delete_board_subscribers.json"
    end
  end
end
