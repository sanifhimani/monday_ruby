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

RSpec.describe Monday::Resources::BoardView, :vcr do
  describe ".query" do
    subject(:response) { client.board_view.query(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      let(:args) do
        {
          ids: board_id
        }
      end

      let!(:create_board) do
        client.board.create(args: { board_name: "Test Board", board_kind: :private })
      end
      let(:board_id) { create_board.body["data"]["create_board"]["id"] }

      it_behaves_like "authenticated client request"

      it "returns the body with board views" do
        expect(
          response.body["data"]["boards"]
        ).to match(array_including(hash_including("views")))
      end
    end
  end
end
