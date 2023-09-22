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

RSpec.describe Monday::Resources::Group, :vcr do
  describe ".groups" do
    subject(:response) { client.groups(select: select) }

    let(:select) { %w[id title] }

    let(:query) { "query { groups() {id title}}" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with ID and title" do
        expect(
          response.body["data"]["boards"].first["groups"]
        ).to match(array_including(hash_including("id", "title")))
      end

      context "when a field that doesn't exist on groups is requested" do
        let(:select) { ["invalid_field"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end
    end
  end

  describe ".create_group" do
    subject(:response) { client.create_group(args: args) }

    let(:query) do
      "mutation { create_group(board_id: #{board_id}, group_id: #{group_id}) {id title}}"
    end

    let(:board_id) { "4408896541" }

    let(:args) do
      {
        board_id: board_id,
        group_name: "Returned orders"
      }
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with created groups ID and Title" do
        expect(
          response.body["data"]["create_group"]
        ).to match(hash_including("id", "title"))
      end

      context "when a field that doesn't exist on groups is given" do
        let(:args) do
          {
            board_id: board_id,
            group_name: "Returned orders",
            invalid_field: "test"
          }
        end

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end
    end
  end

  describe ".update_group" do
    subject(:response) { client.update_group(args: args) }

    let(:query) do
      "mutation {
        update_group(
          board_id: #{board_id},
          group_id: #{group_id},
          group_attribute: title,
          new_value: \"Voided orders\")}"
    end

    let(:board_id) { "4408896541" }
    let(:group_id) do
      args = { board_id: board_id, group_name: "TEST GROUP" }
      retval = valid_client.create_group(args: args)
      retval.body["data"]["create_group"]["id"]
    end

    let(:args) do
      {
        board_id: board_id,
        group_id: group_id,
        group_attribute: "title",
        new_value: "Voided orders"
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
          response.body["data"]["update_group"]
        ).to match(hash_including("id"))
      end

      context "when a the group with the given group ID does not exist" do
        let(:args) do
          {
            board_id: board_id,
            group_id: "dog",
            group_attribute: "title",
            new_value: "Voided orders"
          }
        end

        it "raises Monday::Error error" do
          # This throws an ActiveRecord error on the Monday API side.
          expect { response }.to raise_error(Monday::Error)
        end
      end
    end
  end

  describe ".delete_group" do
    subject(:response) { client.delete_group(args: { board_id: board_id, group_id: group_id }) }

    let(:query) do
      "mutation { delete_group(board_id: #{board_id}, group_id: #{group_id}) {id}}"
    end

    let(:board_id) { "4408896541" }
    let(:group_id) do
      args = { board_id: board_id, group_name: "TEST GROUP" }
      retval = valid_client.create_group(args: args)
      retval.body["data"]["create_group"]["id"]
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it "returns the body with deleted groups ID" do
        expect(
          response.body["data"]["delete_group"]
        ).to match(hash_including("id"))
      end

      context "when a the group with the given group ID does not exist" do
        let(:group_id) { "invalid_group_name" }

        it "raises Monday::ResourceNotFoundError error" do
          expect { response }.to raise_error(Monday::ResourceNotFoundError)
        end
      end
    end
  end

  describe ".duplicate_group" do
    subject(:response) { client.duplicate_group(args: args) }

    let(:query) do
      "mutation { duplicate_group (board_id: #{board_id}, group_id: #{group_id}) {id}}"
    end

    let(:args) do
      {
        board_id: board_id,
        group_id: group_id
      }
    end

    let(:board_id) { "4408896541" }
    let(:group_id) do
      args = { board_id: board_id, group_name: "TEST GROUP" }
      retval = valid_client.create_group(args: args)
      retval.body["data"]["create_group"]["id"]
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it_behaves_like "authenticated client request"

      it "returns the body with duplicated group ID and Title" do
        expect(
          response.body["data"]["duplicate_group"]
        ).to match(hash_including("id", "title"))
      end

      context "when a the group with the given group ID does not exist" do
        let(:args) do
          {
            board_id: board_id,
            group_id: "invalid_group_name"
          }
        end

        it "raises Monday::ResourceNotFoundError error" do
          expect { response }.to raise_error(Monday::ResourceNotFoundError)
        end
      end
    end
  end

  describe ".archive_group" do
    subject(:response) { client.archive_group(args: { board_id: board_id, group_id: group_id }) }

    let(:query) do
      "mutation { archive_group (board_id: #{board_id}, group_id: #{group_id}) {id}}"
    end

    let(:args) do
      {
        board_id: board_id,
        group_id: group_id
      }
    end

    let(:board_id) { "4408896541" }
    let(:group_id) do
      args = { board_id: board_id, group_name: "TEST GROUP" }
      retval = valid_client.create_group(args: args)
      retval.body["data"]["create_group"]["id"]
    end

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it "returns the body with archived groups ID" do
        expect(
          response.body["data"]["archive_group"]
        ).to match(hash_including("id"))
      end

      context "when a the group with the given group ID does not exist" do
        let(:group_id) { "invalid_group_id" }

        it "raises Monday::ResourceNotFoundError error" do
          expect { response }.to raise_error(Monday::ResourceNotFoundError)
        end
      end
    end
  end

  describe ".move_item_to_group" do
    subject(:response) { client.move_item_to_group(args: { item_id: item_id, group_id: group_id }) }

    let(:query) do
      "mutation { move_item_to_group (item_id: #{item_id}, group_id: #{group_id}) {id}"
    end

    let(:board_id) { "4408896541" }
    let(:group_id) { "topics" }
    let(:item_id) { "5204598839" }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      it "returns the body with deleted subscribers ID" do
        expect(
          response.body["data"]["move_item_to_group"]
        ).to match(hash_including("id"))
      end

      context "when a the group with the given group ID does not exist" do
        let(:group_id) { "invalid_group_id" }

        it "raises Monday::ResourceNotFoundError error" do
          expect { response }.to raise_error(Monday::ResourceNotFoundError)
        end
      end
    end
  end
end
