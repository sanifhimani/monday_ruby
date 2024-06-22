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
  describe ".folders" do
    subject(:response) { client.folders(select: select) }

    let(:select) { %w[id name] }

    let(:query) { "query { folders() {id name}}" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with ID and name" do
        expect(
          response.body["data"]["folders"]
        ).to match(array_including(hash_including("id", "name")))
      end

      context "when a field that doesn't exist on folders is requested" do
        let(:select) { ["invalid_field"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end
    end
  end

  describe ".create_folder" do
    subject(:response) { client.create_folder(args: args) }

    let(:query) do
      "mutation { create_folder(name: \"New test folder\") {id name }}"
    end

    let(:args) do
      {
        name: "New test folder"
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with created folders ID and name" do
        expect(
          response.body["data"]["create_folder"]
        ).to match(hash_including("id", "name"))
      end

      context "when a field that doesn't exist on folders is given" do
        let(:args) do
          {
            name: "New test folder",
            invalid_field: "test"
          }
        end

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end
    end
  end

  describe ".update_folder" do
    subject(:response) { client.update_folder(args: args) }

    let(:query) do
      "mutation { update_folder(folder_id: #{folder_id}, name: \"New \")}"
    end

    let(:folder_id) { "4751845443" }

    let(:args) do
      {
        folder_id: folder_id,
        name: "New "
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with update status and undo data" do
        expect(
          JSON.parse(response.body["data"]["update_folder"])
        ).to match(hash_including("success", "undo_data"))
      end

      context "when a the folder with the given folder ID does not exist" do
        let(:args) do
          {
            folder_id: "123",
            name: "New "
          }
        end

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidfolderIdException:/
          )
        end
      end
    end
  end

  describe ".delete_folder" do
    subject(:response) { client.delete_folder(folder_id) }

    let(:query) do
      "mutation { delete_folder(folder_id: #{folder_id}) {id}}"
    end

    let(:folder_id) { "4751845270" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it "returns the body with deleted folders ID" do
        expect(
          response.body["data"]["delete_folder"]
        ).to match(hash_including("id"))
      end

      context "when a the folder with the given folder ID does not exist" do
        let(:folder_id) { "123" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidfolderIdException:/
          )
        end
      end
    end
  end
end
