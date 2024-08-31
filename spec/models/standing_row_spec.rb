# frozen_string_literal: true

RSpec.describe StandingRow do
  let(:player) { create(:player) }
  let(:row) { create(:standing_row, player:) }

  describe '#corp_identity' do
    let!(:identity) { create(:identity, name: 'RP') }

    before do
      player.corp_identity = 'RP'
      player.save!
    end

    it 'delegates to player' do
      expect(row.corp_identity).to eq(identity)
    end
  end

  describe '#runner_identity' do
    let!(:identity) { create(:identity, name: 'Reina Roja') }

    before do
      player.runner_identity = 'Reina Roja'
      player.save!
    end

    it 'delegates to player' do
      expect(row.runner_identity).to eq(identity)
    end
  end
end
