# frozen_string_literal: true

RSpec.describe SelfReportHelper do
  describe '#self_report_allowed' do
    let(:none_empty_self_report) { empty_self_report }
    let(:player_1_with_id) { player_with_id(1) }
    let(:player_2_with_id) { player_with_id(2) }
    let!(:alice) { create(:user, nrdb_username: 'Alice', id: '1') }
    let!(:bob) { create(:user, nrdb_username: 'Bob', id: '2') }
    let!(:charlie) { create(:user, nrdb_username: 'Charlie', id: '3') }

    it 'returns false if current user is nil' do
      expect(helper.self_report_allowed(nil, nil, player_1_with_id, player_2_with_id)).to be false
    end

    it 'returns true if current user 1 is in pairing' do
      expect(helper.self_report_allowed(alice, nil, player_1_with_id,
                                        player_2_with_id)).to be true
    end

    it 'returns true if current user 2 is in pairing' do
      expect(helper.self_report_allowed(bob, nil, player_1_with_id,
                                        player_2_with_id)).to be true
    end

    it 'returns false if self_report exists' do
      expect(helper.self_report_allowed(alice, none_empty_self_report, player_1_with_id,
                                        player_2_with_id)).to be false
    end

    it 'returns false if current user is not part of the pairing' do
      expect(helper.self_report_allowed(charlie, nil, player_1_with_id,
                                        player_2_with_id)).to be false
    end
  end

  def player_with_id(id)
    {
      'user_id' => id
    }
  end

  def create_current_user(id)
    {
      'id' => id
    }
  end

  def empty_self_report
    {
      'score_1' => 1,
      'score_2' => 1
    }
  end
end
