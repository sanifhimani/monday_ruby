# frozen_string_literal: true

RSpec.describe Monday::Resources::Account, :vcr do
  describe ".query" do
    subject(:account) { client.account.query(select: select) }

    let(:select) { %w[id name] }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it "raises Monday::AuthorizationError error" do
        expect { account }.to raise_error(Monday::AuthorizationError)
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

      context "when a field that doesn't exist on account is requested" do
        let(:select) { ["invalid_field"] }

        it "raises Monday::Error error" do
          expect { account }.to raise_error(Monday::Error)
        end
      end
    end
  end
end
