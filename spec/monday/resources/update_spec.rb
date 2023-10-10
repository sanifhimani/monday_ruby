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

RSpec.describe Monday::Resources::Update, :vcr do
  describe ".updates" do
    subject(:response) { client.updates(args: args, select: select) }

    let(:select) { %w[id body created_at] }

    # let(:query) { "query { updates(ids: #{item_id}) {id body created_at}}" }

    let(:args) do
      {
        limit: 10
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

      it "returns the body with item ID, body and created_at" do
        expect(
          response.body["data"]["updates"]
        ).to match(array_including(hash_including("id", "body", "created_at")))
      end

      context "when a field that doesn't exist on items is requested" do
        let(:select) { ["invalid_field"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end
    end
  end

  describe ".create_update" do
    subject(:response) { client.create_update(args: args) }

    # let(:query) do
    #   "mutation { create_update(item_id: #{item_id}, " \
    #     "body: \"This update will be added to the item\") {id body created_at}}"
    # end

    let(:args) do
      {
        item_id: item_id,
        body: "This update will be added to the item"
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

      it "returns the body with the created items ID, body and created_at" do
        expect(
          response.body["data"]["create_update"]
        ).to match(hash_including("id", "body", "created_at"))
      end

      context "when the item_id does not exist" do
        let(:item_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end
    end
  end

  describe ".like_update" do
    subject(:response) { client.like_update(args: args) }

    # let(:query) do
    #   "mutation { like_update(update_id: #{update_id}) {id}}"
    # end

    let(:args) do
      {
        update_id: update_id
      }
    end

    let(:update_id) { "2464728056" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with the update liked ID" do
        expect(
          response.body["data"]["like_update"]
        ).to match(hash_including("id"))
      end

      context "when the update_id does not exist" do
        let(:update_id) { "123" }

        it "raises Monday::AuthorizationError error" do
          expect { response }.to raise_error(Monday::AuthorizationError)
        end
      end
    end
  end

  describe ".clear_item_updates" do
    subject(:response) { client.clear_item_updates(args: args) }

    # let(:query) do
    #   "mutation { clear_item_updates(item_id: #{item_id}) {id}}"
    # end

    let(:args) do
      {
        item_id: item_id
      }
    end

    let(:item_id) { "5204603920" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it "returns the body with the archived item ID" do
        expect(
          response.body["data"]["clear_item_updates"]
        ).to match(hash_including("id"))
      end

      context "when the item does not exist for the given item_id" do
        let(:item_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(Monday::InternalServerError)
        end
      end
    end
  end

  describe ".delete_update" do
    subject(:response) { client.delete_update(args: args) }

    # let(:query) do
    #   "mutation { delete_update(id: #{update_id}) {id}}"
    # end

    let(:args) do
      {
        id: update_id
      }
    end

    let(:update_id) { "2464725070" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it "returns the body with the deleted update ID" do
        expect(
          response.body["data"]["delete_update"]
        ).to match(hash_including("id"))
      end

      context "when the item does not exist for the given item_id" do
        let(:update_id) { "123" }

        it "raises Monday::ResourceNotFoundError error" do
          expect { response }.to raise_error(Monday::ResourceNotFoundError)
        end
      end
    end
  end
end
