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

RSpec.describe Monday::Resources::Folder, :vcr do
  describe ".query" do
    subject(:response) { client.folder.query(select: select) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:select) { %w[id name] }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when an invalid field is requested" do
        let(:select) { ["invalid_field"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when valid fields are requested" do
        let(:select) { %w[id name] }

        it_behaves_like "authenticated client request"

        it "returns the body with ID and name" do
          expect(
            response.body["data"]["folders"]
          ).to match(array_including(hash_including("id", "name")))
        end
      end
    end
  end

  describe ".create" do
    subject(:response) { client.folder.create(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when a field that doesn't exist on folders is given" do
        let(:args) do
          {
            workspace_id: workspace_id,
            name: "Database boards",
            invalid_field: "test"
          }
        end
        let!(:create_workspace) do
          client.workspace.create(args: { name: "Test Workspace", kind: :open })
        end
        let(:workspace_id) { create_workspace.body["data"]["create_workspace"]["id"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when args are valid" do
        let(:args) do
          {
            workspace_id: workspace_id,
            name: "Database boards"
          }
        end
        let!(:create_workspace) do
          client.workspace.create(args: { name: "Test Workspace", kind: :open })
        end
        let(:workspace_id) { create_workspace.body["data"]["create_workspace"]["id"] }

        it_behaves_like "authenticated client request"

        it "returns the body with created folders ID and Title" do
          expect(
            response.body["data"]["create_folder"]
          ).to match(hash_including("id", "name"))
        end
      end
    end
  end

  describe ".update" do
    subject(:response) { client.folder.update(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when a the folder with the given folder ID does not exist" do
        let(:args) do
          {
            folder_id: 1_234_567,
            name: "Dogs"
          }
        end

        it "raises Monday::Error error" do
          # This throws an ActiveRecord error on the Monday API side.
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when args are invalid" do
        let(:args) do
          {
            folder_id: folder_id,
            name: "Some other name",
            invalid_field: "test"
          }
        end
        let!(:create_workspace) do
          client.workspace.create(args: { name: "Test Workspace", kind: :open })
        end
        let(:workspace_id) { create_workspace.body["data"]["create_workspace"]["id"] }
        let!(:create_folder) do
          client.folder.create(args: { workspace_id: workspace_id, name: "Database boards" })
        end
        let(:folder_id) { create_folder.body["data"]["create_folder"]["id"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when args are valid" do
        let(:args) do
          {
            folder_id: folder_id,
            name: "Cool boards"
          }
        end
        let!(:create_workspace) do
          client.workspace.create(args: { name: "Test Workspace", kind: :open })
        end
        let(:workspace_id) { create_workspace.body["data"]["create_workspace"]["id"] }
        let!(:create_folder) do
          client.folder.create(args: { workspace_id: workspace_id, name: "Database boards" })
        end
        let(:folder_id) { create_folder.body["data"]["create_folder"]["id"] }

        it_behaves_like "authenticated client request"

        it "returns the body with updated folders ID" do
          expect(
            response.body["data"]["update_folder"]
          ).to match(hash_including("id"))
        end
      end
    end
  end

  describe ".delete" do
    subject(:response) { client.folder.delete(args: { folder_id: folder_id }) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:folder_id) { "123" }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when a the folder with the given folder ID does not exist" do
        let(:folder_id) { "invalid_folder_name" }

        it "raises Monday::ResourceNotFoundError error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when the args are valid" do
        let!(:create_workspace) do
          client.workspace.create(args: { name: "Test Workspace", kind: :open })
        end
        let(:workspace_id) { create_workspace.body["data"]["create_workspace"]["id"] }
        let!(:create_folder) do
          client.folder.create(args: { workspace_id: workspace_id, name: "Database boards" })
        end
        let(:folder_id) { create_folder.body["data"]["create_folder"]["id"] }

        it_behaves_like "authenticated client request"

        it "returns the body with deleted folders ID" do
          expect(
            response.body["data"]["delete_folder"]
          ).to match(hash_including("id"))
        end
      end
    end
  end
end
