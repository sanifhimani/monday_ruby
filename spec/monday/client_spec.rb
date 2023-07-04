# frozen_string_literal: true

RSpec.describe Monday::Client do
  subject(:client) { described_class.new(config_args) }

  context "when no args are provided" do
    let(:config_args) { {} }

    before do
      Monday.config.reset
    end

    it "creates an instance of Monday::Client with the default token" do
      expect(client.config.token).to be nil
    end

    it "creates an instance of Monday::Client with the default host" do
      expect(client.config.host).to eq(monday_url)
    end
  end

  context "when token is provided" do
    let(:config_args) do
      {
        token: token
      }
    end

    let(:token) { "test_token" }

    it "creates an instance of Monday::Client with the provided token" do
      expect(client.config.token).to eq(token)
    end

    it "creates an instance of Monday::Client with the default host" do
      expect(client.config.host).to eq(monday_url)
    end
  end

  context "when unknown args are provided" do
    let(:config_args) do
      {
        args: "unknown"
      }
    end

    it "raises ArgumentError" do
      expect { client }.to raise_error(ArgumentError, "Unknown arguments: [:args]")
    end
  end
end
