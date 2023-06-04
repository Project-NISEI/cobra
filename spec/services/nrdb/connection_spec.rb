RSpec.describe Nrdb::Connection do
  let(:connection) { described_class.new }

  describe '#cards' do
    it 'fetches card data' do
      VCR.use_cassette :nrdb_cards do
        expect(connection.cards.count).to eq(1381)
      end
    end
  end

  context 'with user' do
    let(:user) { create(:user, nrdb_access_token: 'a_token') }
    let(:connection) { described_class.new(user) }

    describe '#player_info' do
      it 'fetches player info' do
        VCR.use_cassette :nrdb_player_info do
          expect(connection.player_info).to eq([
            "id" => 123,
            "username" => "test_user",
            "email" => "test@test.com",
            "reputation" => 1,
            "sharing" => true
          ])
        end
      end
    end

    describe '#decks' do
      it 'fetches a deck' do
        VCR.use_cassette 'nrdb_decks/simplified_deck' do
          expect(connection.decks).to eq([
              "id" => 123,
              "name" => "My Best Deck"
            ])
        end
      end

      it 'orders decks most recent first' do
        VCR.use_cassette 'nrdb_decks/unordered_decks' do
          expect(connection.decks.map { |deck| deck[:name] })
            .to eq(["Some Deck", "A Perfect Deck", "My Best Deck"])
        end
      end
    end
  end

  context 'with token' do
    let(:connection) { described_class.new(nil, 'a_token') }

    describe '#player_info' do
      it 'fetches player info' do
        VCR.use_cassette :nrdb_player_info do
          expect(connection.player_info).to eq([
            "id" => 123,
            "username" => "test_user",
            "email" => "test@test.com",
            "reputation" => 1,
            "sharing" => true
          ])
        end
      end
    end
  end
end
