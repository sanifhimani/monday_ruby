# frozen_string_literal: true

RSpec.describe Monday::Response do
  subject(:response) { described_class.new(mock_response) }

  before do
    allow(mock_response).to receive(:code).and_return(status_code)
    allow(mock_response).to receive(:body).and_return(body.to_json)
    allow(mock_response).to receive(:each_header).and_return(headers)
  end

  let(:mock_response) { instance_double(Net::HTTPOK) }
  let(:status_code) { "200" }
  let(:headers) { {} }
  let(:body) do
    {
      "data" => "Success data"
    }
  end

  it "returns 200 status code" do
    expect(response.status).to eq(200)
  end

  it "returns the parsed body" do
    expect(response.body).to eq(body)
  end

  it "returns the headers" do
    expect(response.headers).to eq(headers)
  end

  describe "#success?" do
    subject(:success?) { response.success? }

    context "when the status is not 2XX" do
      let(:status_code) { "500" }

      it "returns false" do
        expect(success?).to be false
      end
    end

    context "when the body includes an error message" do
      let(:body) do
        {
          "error_message" => "Error message"
        }
      end

      it "returns false" do
        expect(success?).to be false
      end
    end

    context "when the body does not include an error message" do
      let(:body) do
        {
          "data" => "success"
        }
      end

      it "returns true" do
        expect(success?).to be true
      end
    end
  end
end
