# frozen_string_literal: true

require 'faker'

class DemoTournament
  def self.create(tournament_name: nil, format: nil, first_round_byes: 0, num_players: 0, assign_ids: false, owner: nil)
    corp_ids = []
    runner_ids = []
    Identity.find_each do |id|
      if id.side == 'corp'
        corp_ids << { id: id.id, name: id.name }
      else
        runner_ids << { id: id.id, name: id.name }
      end
    end

    tournament = Tournament.new(name: tournament_name, user: owner, swiss_format: format, private: true)
    tournament.save!

    num_players.times do
      p = Player.new(name: Faker::Name.name, tournament:)
      Rails.logger.debug "  Creating player: #{p.name}"
      if assign_ids
        corp_id = corp_ids.sample(1).first
        p.corp_identity = corp_id[:name]
        p.corp_identity_ref_id = corp_id[:id]
        runner_id = runner_ids.sample(1).first
        p.runner_identity = runner_id[:name]
        p.runner_identity_ref_id = runner_id[:id]
      end
      p.save!

      tournament.current_stage.players << p
    end
    tournament.save!

    if first_round_byes.positive?
      Rails.logger.debug "  Assigning #{first_round_byes} first round byes"
      players = Player.where(tournament:)
      byes = players.sample(first_round_byes)
      byes.each do |bye_player|
        bye_player.first_round_bye = true
        bye_player.save!
      end
    end

    Rails.logger.debug 'Pairing first round'
    tournament.pair_new_round!

    tournament
  end
end
