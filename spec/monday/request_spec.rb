# frozen_string_literal: true

RSpec.describe Monday::Request do
  describe ".post" do
    subject(:post) { described_class.post(uri, query, headers) }

    let(:uri) { URI.parse(monday_url) }
    let(:query) { "query{ boards {id} }" }
    let(:body) do
      {
        query: query
      }
    end
    let(:headers) do
      {
        "Content-Type": "application/json",
        Authorization: token
      }
    end

    context "when authorization token is invalid" do
      let(:token) { "invalid_token" }

      before do
        stub_request(:post, uri)
          .with(body: body.to_json)
          .to_return(status: 403, body: "", headers: {})
      end

      it "returns 403 status" do
        expect(post.code).to eq("403")
      end
    end

    context "when authorization token is valid" do
      let(:token) { "valid_token" }

      before do
        stub_request(:post, uri)
          .with(body: body.to_json)
          .to_return(status: 200, body: "", headers: {})
      end

      it "returns 200 status" do
        expect(post.code).to eq("200")
      end
    end

    context "with timeout configuration" do
      let(:token) { "valid_token" }
      let(:http_spy) { instance_double(Net::HTTP) }
      let(:request_spy) { instance_double(Net::HTTP::Post) }
      let(:response_double) { instance_double(Net::HTTPResponse, code: "200", body: '{"data":{}}') }

      before do
        allow(Net::HTTP).to receive(:new).with(uri.host, uri.port).and_return(http_spy)

        allow(http_spy).to receive(:use_ssl=).with(true)
        allow(http_spy).to receive(:open_timeout=)
        allow(http_spy).to receive(:read_timeout=)
        allow(http_spy).to receive(:request).and_return(response_double)

        allow(Net::HTTP::Post).to receive(:new).with(uri.request_uri, headers).and_return(request_spy)
        allow(request_spy).to receive(:body=)
      end

      it "sets default open_timeout to 10 seconds" do
        described_class.post(uri, query, headers)

        expect(http_spy).to have_received(:open_timeout=).with(10)
      end

      it "sets default read_timeout to 30 seconds" do
        described_class.post(uri, query, headers)

        expect(http_spy).to have_received(:read_timeout=).with(30)
      end

      it "sets custom open_timeout when provided" do
        described_class.post(uri, query, headers, open_timeout: 15)

        expect(http_spy).to have_received(:open_timeout=).with(15)
      end

      it "sets custom read_timeout when provided" do
        described_class.post(uri, query, headers, read_timeout: 45)

        expect(http_spy).to have_received(:read_timeout=).with(45)
      end
    end
  end
end
