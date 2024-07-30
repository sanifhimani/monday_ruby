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
  describe ".query" do
    subject(:response) { client.workspace.query(select: select) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:select) { %w[id name description] }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when an invalid field requested" do
        let(:select) { ["invalid_field"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when valid fields are requested" do
        let(:select) { %w[id name description] }

        before do
          client.workspace.create(args: { name: "Test Workspace", kind: :open, description: "A test workspace" })
        end

        it_behaves_like "authenticated client request"

        it "returns the body with ID, name and description" do
          expect(
            response.body["data"]["workspaces"]
          ).to match(array_including(hash_including("id", "name", "description")))
        end
      end
    end
  end

  describe ".create" do
    subject(:response) { client.workspace.create(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when a field that doesn't exist on workspaces is given" do
        let(:args) do
          {
            name: "New test workspace",
            kind: :private,
            invalid_field: "test"
          }
        end

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when invalid args are given" do
        let(:args) do
          {
            name: "New test workspace",
            kind: "private",
            description: "A new test workspace"
          }
        end

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when valid args are given" do
        let(:args) do
          {
            name: "New test workspace",
            kind: :open,
            description: "A new test workspace"
          }
        end

        it_behaves_like "authenticated client request"

        it "returns the body with ID, name and description of the created workspace" do
          expect(
            response.body["data"]["create_workspace"]
          ).to match(hash_including("id", "name", "description"))
        end
      end
    end
  end

  describe ".delete" do
    subject(:response) { client.workspace.delete(workspace_id) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:workspace_id) { "123" }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when the workspace with the given workspace ID does not exist" do
        let(:workspace_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidWorkspaceIdException:/
          )
        end
      end

      context "when the workspace with the given workspace ID exists" do
        let!(:create_workspace) do
          client.workspace.create(args: { name: "Test Workspace", kind: :open, description: "A test workspace" })
        end
        let(:workspace_id) { create_workspace.body["data"]["create_workspace"]["id"] }

        it_behaves_like "authenticated client request"

        it "returns the body with the ID of the deleted workspace" do
          expect(
            response.body["data"]["delete_workspace"]
          ).to match(hash_including("id"))
        end
      end
    end
  end
end
