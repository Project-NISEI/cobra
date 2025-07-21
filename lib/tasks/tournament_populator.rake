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

    tournament = DemoTournament.create(
      tournament_name: tournament_name,
      format: format,
      first_round_byes: first_round_byes,
      num_players: num_players,
      assign_ids: assign_ids,
      owner: owner
    )

    puts 'Done!'
    puts "Created tournament \"#{tournament.name}\" with ID #{tournament.id}"
  end
end
