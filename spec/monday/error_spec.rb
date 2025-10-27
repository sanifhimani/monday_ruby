# frozen_string_literal: true

RSpec.describe Monday::Error do
  subject(:error) { described_class.new(message: message, response: response, code: code) }

  context "when no params are given" do
    let(:message) { nil }
    let(:response) { nil }
    let(:code) { nil }

    it "creates an empty error object" do
      expect(error.message).to be_nil
    end
  end

  context "when params are given" do
    let(:message) { "Error message" }
    let(:response) { nil }
    let(:code) { 500 }

    it "creates the error object with the given message" do
      expect(error.message).to eq(message)
    end

    it "creates the error object with the given code" do
      expect(error.code).to eq(code)
    end
  end
end
