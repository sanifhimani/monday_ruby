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

RSpec.describe Monday::Resources::BoardView do
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

  describe ".board_views" do
    subject(:response) { client.board_views(args: args) }

    let(:query) { "query { boards(ids: 123) { views {id name type}}}" }

    let(:args) do
      {
        ids: 123
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "board_view/board_views.json"
    end
  end
end
