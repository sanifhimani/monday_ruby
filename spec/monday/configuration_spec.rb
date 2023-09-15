# frozen_string_literal: true

RSpec.describe Monday::Configuration do
  subject(:config) { described_class.new(**config_args) }

  let(:test_token) { "test-token" }
  let(:test_host) { "https://monday.com/v2" }
  let(:test_version) { "2023-10" }

  describe "initialize" do
    context "when config args are not given" do
      let(:config_args) { {} }

      it { expect(config.host).to eq(described_class::DEFAULT_HOST) }
      it { expect(config.token).to eq(described_class::DEFAULT_TOKEN) }
      it { expect(config.version).to eq(described_class::DEFAULT_VERSION) }
    end

    context "when config args are given" do
      let(:config_args) do
        {
          token: test_token,
          host: test_host,
          version: test_version
        }
      end

      it { expect(config.host).to eq(test_host) }
      it { expect(config.token).to eq(test_token) }
      it { expect(config.version).to eq(test_version) }
    end
  end

  describe ".reset" do
    let(:config_args) do
      {
        token: test_token,
        host: test_host,
        version: test_version
      }
    end

    before do
      config.reset
    end

    it { expect(config.host).to eq(described_class::DEFAULT_HOST) }
    it { expect(config.token).to eq(described_class::DEFAULT_TOKEN) }
    it { expect(config.version).to eq(described_class::DEFAULT_VERSION) }
  end
end
