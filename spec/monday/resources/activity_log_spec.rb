# frozen_string_literal: true

RSpec.describe Monday::Resources::ActivityLog, :vcr do
  describe ".query" do
    subject(:activity_logs) { client.activity_log.query(board_ids) }

    context "when client is not authenticated" do
      let(:board_ids) { "123456" }

      let(:client) { invalid_client }

      it "raises Monday::AuthorizationError error" do
        expect { activity_logs }.to raise_error(Monday::AuthorizationError)
      end
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      let!(:create_board) do
        client.board.create(args: { board_name: "Test Board", board_kind: :private })
      end

      let(:board_ids) { create_board.body["data"]["create_board"]["id"] }

      before do
        client.board.create(args: { board_name: "Test Board", board_kind: :public })
      end

      it "returns 200 status" do
        expect(activity_logs.status).to eq(200)
      end

      it "returns the body with activity ID, event and data" do
        expect(
          activity_logs.body["data"]["boards"].first["activity_logs"]
        ).to match(array_including(hash_including("id", "event", "data")))
      end
    end
  end
end
