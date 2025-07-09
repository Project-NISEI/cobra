# frozen_string_literal: true

require 'faker'

# The following environment variables can be set to control the tournament created:
#     TOURNAMENT_NAME - The name of the tournament, defaults to Time.now.to_s (2025-07-06 23:34:12 +0000)
#     FIRST_ROUND_BYES - The number of players with first round byes, defaults to 0
#     FORMAT - The swiss format to use, defaults to single_sided.
#     NUM_PLAYERS - The number of players in the tournament, defaults to 150
#     ASSIGN_IDS - If set to true, assigns IDs to players, defaults to true
#     OWNER_USERNAME - The username of the owner of the tournament

namespace :tournament_populator do
  desc 'create a tournament with fake players'
  task create: :environment do
    puts "Creating a new tournament in environment: #{Rails.env}"

    tournament_name = ENV.fetch('TOURNAMENT_NAME', "Test Tournament - #{Time.zone.now}")
    format = ENV.fetch('FORMAT', 'single_sided').to_sym
    first_round_byes = ENV.fetch('FIRST_ROUND_BYES', 0).to_i
    num_players = ENV.fetch('NUM_PLAYERS', 150).to_i
    assign_ids = ENV.fetch('ASSIGN_IDS', 'true') == 'true'
    owner_username = ENV.fetch('OWNER_USERNAME', '')

    # Validate
    abort 'Tournament name cannot be empty' if tournament_name.empty?
    abort 'Format must be a valid swiss format' unless %i[single_sided double_sided].include?(format)
    abort 'First round byes must be a non-negative integer' if first_round_byes.negative?
    abort 'Num players must be a non-negative integer' if num_players.negative?
    abort 'First round byes cannot exceed the number of players' if first_round_byes > num_players
    abort 'Owner username cannot be empty' if owner_username.empty?

    owner = User.find_by(nrdb_username: owner_username)
    abort "Owner with username '#{owner_username}' not found" unless owner

    puts 'Creating tournament with the following parameters:'
    puts "  Tournament Name: #{tournament_name}"
    puts "  Owner Username: #{owner_username}"
    puts "  Format: #{format}"
    puts "  Number of Players: #{num_players}"
    puts "  First Round Byes: #{first_round_byes}"
    puts "  Assign IDs: #{assign_ids}"
    puts ''

    corp_ids = []
    runner_ids = []
    Identity.find_each do |id|
      if id.side == 'corp'
        corp_ids << { id: id.id, name: id.name }
      else
        runner_ids << { id: id.id, name: id.name }
      end
    end

    tournament = Tournament.new(name: tournament_name, user: owner, swiss_format: format)
    tournament.save!

    num_players.times do
      p = Player.new(name: Faker::Name.name, tournament:)
      puts "  Creating player: #{p.name}"
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
      puts "  Assigning #{first_round_byes} first round byes"
      players = Player.where(tournament:)
      byes = players.sample(first_round_byes)
      byes.each do |bye_player|
        bye_player.first_round_bye = true
        bye_player.save!
      end
    end

    puts 'Pairing first round'
    tournament.pair_new_round!

    puts 'Done!'
  end
end
