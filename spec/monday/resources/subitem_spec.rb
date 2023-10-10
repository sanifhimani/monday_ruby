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
  describe ".subitems" do
    subject(:response) { client.subitems(args: args, select: select) }

    let(:select) { %w[id name created_at] }

    let(:query) { "query { items(ids: #{item_id}) { subitems{id name created_at}}}" }

    let(:args) do
      {
        ids: item_id
      }
    end

    let(:item_id) { "5204603920" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with item ID, name and created_at" do
        expect(
          response.body["data"]["items"].first["subitems"]
        ).to match(array_including(hash_including("id", "name", "created_at")))
      end

      context "when a field that doesn't exist on items is requested" do
        let(:select) { ["invalid_field"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end
    end
  end

  describe ".create_subitem" do
    subject(:response) { client.create_subitem(args: args) }

    let(:query) do
      "mutation {
        create_subitem(
          parent_item_id: 5204603920,
          item_name: \"New Item Test\",
          column_values: \"{
            \\\"person\\\":{\\\"personsAndTeams\\\":[{\\\"id\\\":42835270,\\\"kind\\\":\\\"person\\\"}]},
            \\\"status\\\":\\\"Done\\\",
            \\\"date0\\\":\\\"2021-09-15\\\"}\")
        {id name created_at}}"
    end

    let(:args) do
      {
        parent_item_id: item_id,
        item_name: "New Item Test",
        column_values: {
          person: { personsAndTeams: [{ id: 42835270, kind: "person" }] },
          status: "Done",
          date0: "2021-09-15"
        }
      }
    end

    let(:item_id) { "5204603920" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with the created items ID, name and created_at" do
        expect(
          response.body["data"]["create_subitem"]
        ).to match(hash_including("id", "name", "created_at"))
      end

      context "when the item_id does not exist" do
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
end
