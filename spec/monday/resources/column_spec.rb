# frozen_string_literal: true

RSpec.shared_examples "unauthenticated client request" do
  before do
    stub_request(:post, uri)
      .with(body: body.to_json)
      .to_return(status: 401, body: fixture("unauthenticated.json"))
  end

  it "returns 401 status" do
    expect(response.status).to eq(401)
  end
end

RSpec.shared_examples "authenticated client request" do |fixture|
  before do
    stub_request(:post, uri)
      .with(body: body.to_json)
      .to_return(status: 200, body: fixture(fixture))
  end

  it "returns 200 status" do
    expect(response.status).to eq(200)
  end
end

RSpec.describe Monday::Resources::Column do
  let(:uri) { URI.parse(monday_url) }
  let(:body) do
    {
      query: query
    }
  end

  let(:invalid_client) do
    Monday::Client.new(token: nil)
  end

  let(:valid_client) do
    Monday::Client.new(token: "xxx")
  end

  describe ".columns" do
    subject(:response) { client.columns }

    let(:query) { "query { boards() { columns {id title description}}}" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "column/columns.json"
    end
  end

  describe ".column_values" do
    subject(:response) { client.column_values }

    let(:query) { "query { boards () { items () { column_values {id title description}}}}" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "column/column_values.json"
    end
  end

  describe ".create_column" do
    subject(:response) { client.create_column(args: args) }

    let(:query) do
      "mutation { create_column(board_id: 1234, title: Status, description: \"Status Column\", column_type: text) " \
        "{id title description}}"
    end

    let(:args) do
      {
        board_id: 1234,
        title: "Status",
        description: "Status Column",
        column_type: "text"
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "column/create_column.json"
    end
  end

  describe ".change_column_title" do
    subject(:response) { client.change_column_title(args: args) }

    let(:query) do
      "mutation { change_column_title(board_id: 1234, column_id: status, title: \"New status\") {id title description}}"
    end

    let(:args) do
      {
        board_id: 1234,
        column_id: "status",
        title: "New status"
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "column/change_column_title.json"
    end
  end

  describe ".change_column_metadata" do
    subject(:response) { client.change_column_metadata(args: args) }

    let(:query) do
      "mutation { change_column_metadata(board_id: 1234, column_id: status, " \
        "column_property: description, value: \"New status description\") " \
        "{id title description}}"
    end

    let(:args) do
      {
        board_id: 1234,
        column_id: "status",
        column_property: "description",
        value: "New status description"
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "column/change_column_metadata.json"
    end
  end

  describe ".change_column_value" do
    subject(:response) { client.change_column_value(args: args) }

    let(:query) do
      "mutation { change_column_value(board_id: 1234, item_id: 4567, column_id: keywords, " \
        "value: \"{\\\"labels\\\":[\\\"Tech\\\"]}\") {id name}}"
    end

    let(:args) do
      {
        board_id: 1234,
        item_id: 4567,
        column_id: "keywords",
        value: {
          labels: ["Tech"]
        }
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "column/change_column_value.json"
    end
  end

  describe ".change_simple_column_value" do
    subject(:response) { client.change_simple_column_value(args: args) }

    let(:query) do
      "mutation { change_simple_column_value(board_id: 1234, item_id: 4567, column_id: status, " \
        "value: \"Working on it\") {id name}}"
    end

    let(:args) do
      {
        board_id: 1234,
        item_id: 4567,
        column_id: "status",
        value: "Working on it"
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "column/change_simple_column_value.json"
    end
  end

  describe ".change_multiple_column_value" do
    subject(:response) { client.change_multiple_column_value(args: args) }

    let(:query) do
      "mutation { change_multiple_column_values(board_id: 1234, item_id: 4567, " \
        "column_values: \"{\\\"status\\\":{\\\"label\\\":\\\"Done\\\"}," \
        "\\\"keywords\\\":{\\\"labels\\\":[\\\"Tech\\\",\\\"Marketing\\\"]}}\") {id name}}"
    end

    let(:args) do
      {
        board_id: 1234,
        item_id: 4567,
        column_values: {
          status: {
            label: "Done"
          },
          keywords: {
            labels: %w[Tech Marketing]
          }
        }
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "column/change_multiple_column_value.json"
    end
  end

  describe ".delete_column" do
    subject(:response) { client.delete_column(board_id, column_id) }

    let(:query) do
      "mutation { delete_column(board_id: 1234, column_id: status) {id}}"
    end

    let(:board_id) { 1234 }
    let(:column_id) { "status" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request", "column/delete_column.json"
    end
  end
end
