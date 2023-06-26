# frozen_string_literal: true

RSpec.describe Monday::Util do
  describe ".format_args" do
    subject(:format_args) { described_class.format_args(object) }

    let(:object) do
      {
        key: value
      }
    end

    context "when object has values that only contains single words" do
      let(:value) { "hello" }

      it "returns the formatted object string with key value pairs" do
        expect(format_args).to eq("key: hello")
      end
    end

    context "when object has values that contains multiple words" do
      let(:value) { "hello world" }

      it "returns the formatted object string with key value pairs" do
        expect(format_args).to eq("key: \"hello world\"")
      end
    end
  end

  describe ".format_select" do
    subject(:format_select) { described_class.format_select(array) }

    context "when the array only contains strings" do
      let(:array) { %w[hello world] }

      it "returns the formatted array string" do
        expect(format_select).to eq("hello world")
      end
    end

    context "when the array contains nested hash" do
      let(:array) do
        ["hello", { numbers: %w[one two] }, "world"]
      end

      it "returns the formatted array string" do
        expect(format_select).to eq("hello numbers { one two } world")
      end
    end
  end
end
