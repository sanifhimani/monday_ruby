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

RSpec.describe Monday::Resources::Board, :vcr do
  describe ".query" do
    subject(:response) { client.board.query(select: select) }

    let(:select) { %w[id name description] }

    context "when client is not authenticated" do
      let(:client) { invalid_client }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      before do
        client.board.create(args: { board_name: "Test Board", board_kind: :private })
      end

      it_behaves_like "authenticated client request"

      it "returns the body with ID, name and description" do
        expect(
          response.body["data"]["boards"]
        ).to match(array_including(hash_including("id", "name", "description")))
      end

      context "when a field that doesn't exist on boards is requested" do
        let(:select) { ["invalid_field"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end
    end
  end

  describe ".create" do
    subject(:response) { client.board.create(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when args are invalid" do
        let(:args) do
          {
            board_name: "New test board",
            board_kind: "private"
          }
        end

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when args are valid" do
        let(:args) do
          {
            board_name: "New test board",
            board_kind: :private
          }
        end

        it_behaves_like "authenticated client request"

        it "returns the body with created boards ID, name and description" do
          expect(
            response.body["data"]["create_board"]
          ).to match(hash_including("id", "name", "description"))
        end
      end
    end
  end

  describe ".duplicate" do
    subject(:response) { client.board.duplicate(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when args are invalid" do
        let(:args) do
          {
            board_id: board_id,
            duplicate_type: "duplicate_board_with_structure"
          }
        end

        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when args are valid" do
        let(:args) do
          {
            board_id: board_id,
            duplicate_type: :duplicate_board_with_structure
          }
        end

        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

        it_behaves_like "authenticated client request"

        it "returns the body with duplicated boards ID, name and description" do
          expect(
            response.body["data"]["duplicate_board"]["board"]
          ).to match(hash_including("id", "name", "description"))
        end
      end
    end
  end

  describe ".update" do
    subject(:response) { client.board.update(args: args) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:args) { {} }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when args are invalid" do
        let(:args) do
          {
            board_id: board_id,
            board_attribute: "description",
            new_value: "New description"
          }
        end

        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

        it "raises Monday::Error error" do
          expect { response }.to raise_error(Monday::Error)
        end
      end

      context "when args are valid" do
        let(:args) do
          {
            board_id: board_id,
            board_attribute: :description,
            new_value: "New description"
          }
        end

        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

        it_behaves_like "authenticated client request"

        it "returns the body with update status and undo data" do
          expect(
            JSON.parse(response.body["data"]["update_board"])
          ).to match(hash_including("success", "undo_data"))
        end
      end
    end
  end

  describe ".archive" do
    subject(:response) { client.board.archive(board_id) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:board_id) { "123456" }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when the board does not exist" do
        let(:board_id) { "123" }

        it "raises Monday::AuthorizationError error" do
          expect { response }.to raise_error(Monday::AuthorizationError)
        end
      end

      context "when the board exists" do
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

        it "returns the body with archived boards ID" do
          expect(
            response.body["data"]["archive_board"]
          ).to match(hash_including("id"))
        end
      end
    end
  end

  describe ".delete" do
    subject(:response) { client.board.delete(board_id) }

    context "when client is not authenticated" do
      let(:client) { invalid_client }
      let(:board_id) { "132456" }

      it_behaves_like "unauthenticated client request"
    end

    context "when client is authenticated" do
      let(:client) { valid_client }

      context "when the board does not exist" do
        let(:board_id) { "123456" }

        it "raises Monday::InvalidRequestError error" do
          expect { response }.to raise_error(
            Monday::InvalidRequestError,
            /InvalidBoardIdException:/
          )
        end
      end

      context "when the board exists" do
        let!(:create_board) do
          client.board.create(args: { board_name: "Test Board", board_kind: :private })
        end
        let(:board_id) { create_board.body["data"]["create_board"]["id"] }

        it "returns the body with deleted boards ID" do
          expect(
            response.body["data"]["delete_board"]
          ).to match(hash_including("id"))
        end
      end
    end
  end
end
