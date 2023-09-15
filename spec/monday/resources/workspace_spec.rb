# frozen_string_literal: true

RSpec.shared_examples "unauthenticated client request" do
  it "raises Monday::AuthorizationError error" do
    expect { response }.to raise_error(Monday::AuthorizationError)
  end
end

RSpec.shared_examples "authenticated client request" do
  it "returns 200 status" do
    expect(response.status).to eq(200)
  end
end

RSpec.describe Monday::Resources::Workspace, :vcr do
  describe ".workspaces" do
    subject(:response) { client.workspaces(select: select) }

    let(:select) { %w[id name description] }

    let(:query) { "query { workspaces() {id name description}}" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with ID, name and description" do
        expect(
          response.body["data"]["workspaces"]
        ).to match(array_including(hash_including("id", "name", "description")))
      end

      context "when a field that doesn't exist on workspaces is requested" do
        let(:select) { ["invalid_field"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end
    end
  end

  describe ".create_workspace" do
    subject(:response) { client.create_workspace(args: args) }

    let(:query) do
      <<-QUERY.squish
        mutation {
          create_workspace(name: "New test workspace", kind: "open", description: "A new test workspace") {
            id name description}
        }
      QUERY
    end

    let(:args) do
      {
        name: "New test workspace",
        kind: "open",
        description: "A new test workspace"
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with created workspaces ID, name and description" do
        expect(
          response.body["data"]["create_workspace"]
        ).to match(hash_including("id", "name", "description"))
      end

      context "when a field that doesn't exist on workspaces is given" do
        let(:args) do
          {
            name: "New test workspace",
            kind: "private",
            invalid_field: "test"
          }
        end

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end
    end
  end

  describe ".delete_workspace" do
    subject(:response) { client.delete_workspace(workspace_id) }

    let(:query) do
      "mutation { delete_workspace(workspace_id: #{workspace_id}) {id}}"
    end

    let(:workspace_id) { "3230793" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it "returns the body with deleted workspaces ID" do
        expect(
          response.body["data"]["delete_workspace"]
        ).to match(hash_including("id"))
      end

      context "when a the workspace with the given workspace ID does not exist" do
        let(:workspace_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidWorkspaceIdException:/
          )
        end
      end
    end
  end
end
