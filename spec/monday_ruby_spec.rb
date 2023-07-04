# frozen_string_literal: true

RSpec.describe Monday do
  describe "configuration" do
    before do
      described_class.configure do |config|
        config.token = "test-token"
      end
    end

    it "takes a block to set config" do
      expect(described_class.config.token).to eq("test-token")
    end

    it "updates the token after being configured" do
      described_class.config.token = "updated-token"
      expect(described_class.config.token).to eq("updated-token")
    end
  end
end
