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

RSpec.describe Monday::Resources::BoardView, :vcr do
  describe ".board_views" do
    subject(:response) { client.board_views(args: args) }

    let(:query) { "query { boards(ids: #{board_id}) { views {id name type}}}" }

    let(:board_id) { "4751837459" }
    let(:args) do
      {
        ids: board_id
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with board views" do
        expect(
          response.body["data"]["boards"]
        ).to match(array_including(hash_including("views")))
      end
    end
  end
end
