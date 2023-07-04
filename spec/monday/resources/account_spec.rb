# frozen_string_literal: true

RSpec.describe Monday::Resources::Account, :vcr do
  describe ".account" do
    subject(:account) { client.account }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it "returns 401 status" do
        expect(account.status).to eq(401)
      end
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it "returns 200 status" do
        expect(account.status).to eq(200)
      end

      it "returns the body with the account ID and name" do
        expect(
          account.body["data"]["users"].first["account"]
        ).to match(hash_including("id", "name"))
      end
    end
  end
end
