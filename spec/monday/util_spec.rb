# frozen_string_literal: true

STATUS_CODE_EXCEPTION_CLASS_MAP = [
  [500, Monday::InternalServerError],
  [429, Monday::RateLimitError],
  [404, Monday::ResourceNotFoundError],
  [403, Monday::AuthorizationError],
  [401, Monday::AuthorizationError],
  [400, Monday::InvalidRequestError]
].freeze

RESPONSE_ERROR_EXCEPTION_CLASS_MAP = [
  ["ComplexityException", [Monday::ComplexityError, 429]],
  ["UserUnauthorizedException", [Monday::AuthorizationError, 403]],
  ["ResourceNotFoundException", [Monday::ResourceNotFoundError, 404]],
  ["InvalidUserIdException", [Monday::InvalidRequestError, 400]],
  ["InvalidVersionException", [Monday::InvalidRequestError, 400]],
  ["InvalidColumnIdException", [Monday::InvalidRequestError, 400]],
  ["InvalidBoardIdException", [Monday::InvalidRequestError, 400]],
  ["InvalidArgumentException", [Monday::InvalidRequestError, 400]],
  ["CreateBoardException", [Monday::InvalidRequestError, 400]],
  ["ItemsLimitationException", [Monday::InvalidRequestError, 400]],
  ["ItemNameTooLongException", [Monday::InvalidRequestError, 400]],
  ["ColumnValueException", [Monday::InvalidRequestError, 400]],
  ["CorrectedValueException", [Monday::InvalidRequestError, 400]]
].freeze

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

  describe ".status_code_exceptions_mapping" do
    subject(:status_code_exceptions_mapping) { described_class.status_code_exceptions_mapping(status_code) }

    STATUS_CODE_EXCEPTION_CLASS_MAP.each do |code, klass|
      context "when the status code is #{code}" do
        let(:status_code) { code }

        it "returns the error class specific to the #{code} status code" do
          expect(status_code_exceptions_mapping).to eq(klass)
        end
      end
    end

    context "when some other status code is given" do
      let(:status_code) { 502 }

      it "returns the general error class" do
        expect(status_code_exceptions_mapping).to eq(Monday::Error)
      end
    end
  end

  describe ".response_error_exceptions_mapping" do
    subject(:response_error_exceptions_mapping) { described_class.response_error_exceptions_mapping(error_code) }

    RESPONSE_ERROR_EXCEPTION_CLASS_MAP.each do |code, mapping|
      context "when the error code is #{code}" do
        let(:error_code) { code }

        it "returns the error class specific to the #{code} error code" do
          expect(response_error_exceptions_mapping[0]).to eq(mapping[0])
        end

        it "returns the error code specific to the #{code} error code" do
          expect(response_error_exceptions_mapping[1]).to eq(mapping[1])
        end
      end
    end

    context "when some other error code is given" do
      let(:error_code) { "InvalidErrorCode" }

      it "returns the general error class" do
        expect(response_error_exceptions_mapping[0]).to eq(Monday::Error)
      end

      it "returns the error code as 400" do
        expect(response_error_exceptions_mapping[1]).to eq(400)
      end
    end
  end
end
