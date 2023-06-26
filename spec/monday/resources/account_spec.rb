# frozen_string_literal: true

RSpec.describe Monday::Resources::Account do
  let(:uri) { URI.parse(monday_url) }
  let(:query) { "query { users { account {id name}}}" }
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

  describe ".account" do
    context "when client is not authenticated" do
      subject(:account) { invalid_client.account }

      before do
        stub_request(:post, uri)
          .with(body: body.to_json)
          .to_return(status: 401, body: fixture("unauthenticated.json"))
      end

      it "returns 401 status" do
        expect(account.status).to eq(401)
      end
    end

    context "when client is authenticated" do
      subject(:account) { valid_client.account }

      before do
        stub_request(:post, uri)
          .with(body: body.to_json)
          .to_return(status: 200, body: fixture("account/account.json"))
      end

      it "returns 200 status" do
        expect(account.status).to eq(200)
      end
    end
  end
end
