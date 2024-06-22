# frozen_string_literal: true

RSpec.describe Monday::Resources::Me, :vcr do
  describe ".me" do
    subject(:me) { client.me(select: select) }

    let(:select) { %w[id name] }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it "raises Monday::AuthorizationError error" do
        expect { me }.to raise_error(Monday::AuthorizationError)
      end
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it "returns 200 status" do
        expect(me.status).to eq(200)
      end

      it "returns the body with the me ID and name" do
        expect(
          me.body["data"]["me"]
        ).to match(hash_including("id", "name"))
      end

      context "when a field that doesn't exist on me is requested" do
        let(:select) { ["logos"] }

        it "raises Monday::Error error" do
          expect { me }.to raise_error(Monday::Error)
        end
      end
    end
  end
end
