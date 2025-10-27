# frozen_string_literal: true

RSpec.describe Monday::Client do
  subject(:client) { described_class.new(config_args) }

  context "when no args are provided" do
    let(:config_args) { {} }

    before do
      Monday.config.reset
    end

    it "creates an instance of Monday::Client with the default token" do
      expect(client.config.token).to be_nil
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

  describe "#response_exception" do
    let(:client) { described_class.new(token: "test_token") }

    context "when response has top-level error_code" do
      let(:response) do
        instance_double(
          Monday::Response,
          body: { "error_code" => "ComplexityException" },
          status: 200
        )
      end

      it "extracts error code from top level" do
        exception = client.send(:response_exception, response)
        expect(exception).to be_a(Monday::ComplexityError)
      end
    end

    context "when response has GraphQL errors array with extensions.code" do
      let(:response) do
        instance_double(
          Monday::Response,
          body: {
            "errors" => [
              {
                "message" => "User unauthorized to perform action",
                "extensions" => {
                  "code" => "USER_UNAUTHORIZED",
                  "status_code" => 403
                }
              }
            ]
          },
          status: 200
        )
      end

      it "extracts error code from GraphQL errors array" do
        exception = client.send(:response_exception, response)
        expect(exception).to be_a(Monday::AuthorizationError)
      end
    end

    context "when response has no recognizable error code" do
      let(:response) do
        instance_double(
          Monday::Response,
          body: { "errors" => "Some error message" },
          status: 500
        )
      end

      it "returns generic Monday::Error" do
        exception = client.send(:response_exception, response)
        expect(exception).to be_a(Monday::Error)
      end
    end
  end
end
