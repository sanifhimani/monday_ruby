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

RSpec.describe Monday::Resources::Item, :vcr do
  describe ".items" do
    subject(:response) { client.items(args: args) }

    let(:query) { "query { items(ids: #{item_id}) {id name created_at}}" }

    let(:args) do
      {
        ids: item_id
      }
    end

    let(:item_id) { "4751837477" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with item ID, name and created_at" do
        expect(
          response.body["data"]["items"]
        ).to match(array_including(hash_including("id", "name", "created_at")))
      end
    end
  end

  describe ".create_item" do
    subject(:response) { client.create_item(args: args) }

    let(:query) do
      "mutation { create_item(board_id: #{board_id}, item_name: \"New item\", " \
        "column_values: \"{\\\"status8\\\":{\\\"label\\\":\\\"Working on it\\\"}}\") {id name created_at}}"
    end

    let(:args) do
      {
        board_id: board_id,
        item_name: "New item",
        column_values: {
          status8: {
            label: "Working on it"
          }
        }
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

      it "returns the body with the created items ID, name and created_at" do
        expect(
          response.body["data"]["create_item"]
        ).to match(hash_including("id", "name", "created_at"))
      end
    end
  end

  describe ".duplicate_item" do
    subject(:response) { client.duplicate_item(board_id, item_id, with_updates) }

    let(:query) do
      "mutation { duplicate_item(board_id: #{board_id}, item_id: #{item_id}, " \
        "with_updates: true) {id name created_at}}"
    end

    let(:board_id) { "4751837459" }
    let(:item_id) { "4751837477" }
    let(:with_updates) { true }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with the duplicate items ID, name and created_at" do
        expect(
          response.body["data"]["duplicate_item"]
        ).to match(hash_including("id", "name", "created_at"))
      end
    end
  end

  describe ".archive_item" do
    subject(:response) { client.archive_item(item_id) }

    let(:query) do
      "mutation { archive_item(item_id: #{item_id}) {id}}"
    end

    let(:item_id) { "4751837477" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it "returns the body with the archived item ID" do
        expect(
          response.body["data"]["archive_item"]
        ).to match(hash_including("id"))
      end
    end
  end

  describe ".delete_item" do
    subject(:response) { client.delete_item(item_id) }

    let(:query) do
      "mutation { delete_item(item_id: #{item_id}) {id}}"
    end

    let(:item_id) { "4751837477" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it "returns the body with the deleted item ID" do
        expect(
          response.body["data"]["delete_item"]
        ).to match(hash_including("id"))
      end
    end
  end
end
