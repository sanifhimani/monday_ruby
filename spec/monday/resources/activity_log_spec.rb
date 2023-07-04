# frozen_string_literal: true

RSpec.describe Monday::Resources::ActivityLog, :vcr do
  subject(:activity_logs) { client.activity_logs(board_ids) }

  let(:uri) { URI.parse(monday_url) }
  let(:query) { "query { boards(ids: #{board_ids}) { activity_logs() {id event data}}}" }
  let(:body) do
    {
      query: query
    }
  end

  let(:board_ids) { "123" }

  describe ".activity_logs" do
    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it "returns 401 status" do
        expect(activity_logs.status).to eq(401)
      end
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

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
