# frozen_string_literal: true

RSpec.describe Monday::Deprecation do
  describe ".warn" do
    subject(:warn) do
      described_class.warn(method_name: method_name, removal_version: removal_version, alternative: alternative)
    end

    context "when alternative is provided" do
      let(:method_name) { "items" }
      let(:removal_version) { "2.0.0" }
      let(:alternative) { "items_page" }

      it "outputs deprecation warning to stderr" do
        expect { warn }.to output(
          "[DEPRECATION] `items` is deprecated and will be removed in v2.0.0. Use `items_page` instead.\n"
        ).to_stderr
      end
    end

    context "when alternative is not provided" do
      let(:method_name) { "old_method" }
      let(:removal_version) { "2.0.0" }
      let(:alternative) { nil }

      it "outputs deprecation warning without alternative" do
        expect { warn }.to output(
          "[DEPRECATION] `old_method` is deprecated and will be removed in v2.0.0.\n"
        ).to_stderr
      end
    end
  end
end
