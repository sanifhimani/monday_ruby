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

RSpec.describe Monday::Resources::Item do
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

  describe ".items" do
    subject(:response) { client.items(args: args) }

    let(:query) { "query { items(ids: 4567) {id name created_at}}" }

    let(:args) do
      {
        ids: 4567
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "item/items.json"
    end
  end

  describe ".create_item" do
    subject(:response) { client.create_item(args: args) }

    let(:query) do
      "mutation { create_item(board_id: 1234, item_name: \"New item\", " \
        "column_values: \"{\\\"status\\\":{\\\"label\\\":\\\"Working on it\\\"}}\") {id name created_at}}"
    end

    let(:args) do
      {
        board_id: 1234,
        item_name: "New item",
        column_values: {
          status: {
            label: "Working on it"
          }
        }
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "item/create_item.json"
    end
  end

  describe ".duplicate_item" do
    subject(:response) { client.duplicate_item(board_id, item_id, with_updates) }

    let(:query) do
      "mutation { duplicate_item(board_id: 1234, item_id: 4567, with_updates: true) {id name created_at}}"
    end

    let(:board_id) { 1234 }
    let(:item_id) { 4567 }
    let(:with_updates) { true }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "item/duplicate_item.json"
    end
  end

  describe ".archive_item" do
    subject(:response) { client.archive_item(item_id) }

    let(:query) do
      "mutation { archive_item(item_id: 7890) {id}}"
    end

    let(:item_id) { 7890 }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "item/archive_item.json"
    end
  end

  describe ".delete_item" do
    subject(:response) { client.delete_item(item_id) }

    let(:query) do
      "mutation { delete_item(item_id: 7890) {id}}"
    end

    let(:item_id) { 7890 }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "item/delete_item.json"
    end
  end
end
