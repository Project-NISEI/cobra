# frozen_string_literal: true

require 'stackprof'

# To run this in profiling mode, set PROFILE=1 in the environment.
# This uses stackprof and generates profile files in the current directory.
# See https://github.com/tmm1/stackprof?tab=readme-ov-file#sampling for more info on working with stackprof.

RSpec.describe 'load testing' do
  ROUNDS = 15 # rubocop:disable Lint/ConstantDefinitionInBlock,RSpec/LeakyConstantDeclaration
  PLAYERS = 150 # rubocop:disable Lint/ConstantDefinitionInBlock,RSpec/LeakyConstantDeclaration

  let(:tournament) { create(:tournament, swiss_format: :double_sided) }

  def timer
    (Time.zone.now - (@start || Time.zone.now)).seconds.tap do
      @start = Time.zone.now
    end
  end

  it 'can handle load' do
    timer
    sign_in tournament.user
    puts 'Creating players'
    PLAYERS.times { create(:player, tournament:) }
    expect(tournament.players.count).to equal(PLAYERS)
    puts "\tDone. Took #{timer} seconds"

    active_players = PLAYERS
    ROUNDS.times do |i|
      puts "Round #{i + 1}"
      round = nil

      puts "\tPairing #{tournament.players.active.count} players"
      if ENV['PROFILE'] == '1'
        StackProf.run(mode: :cpu, out: "pair-round-#{i + 1}", raw: true) do
          round = tournament.pair_new_round!
        end
      else

        round = tournament.pair_new_round!
      end
      puts "\t\tDone. Took #{timer} seconds"
      expect(round.pairings.count).to eq((active_players / 2.0).ceil)
      players = round.pairings.map(&:players).flatten
      expect(players.map(&:id) - [nil]).to match_array(tournament.players.active.map(&:id))
      expect(players.select { |p| p.is_a? NilPlayer }.length).to be < 2

      puts "\tGenerating results"
      ActiveRecord::Base.transaction do
        round.pairings.each do |p|
          # score = [[6, 0], [4, 1], [3, 3], [0, 6]].sample
          score = [[3, 0], [0, 3], [1, 1]].sample
          # visit tournament_rounds_path(tournament)
          p.update(score1: score.first, score2: score.last)
        end
        tournament.players.active.shuffle.take(3).each { |p| p.update(active: false) }
        active_players -= 3
        round.update(completed: true)
      end
      puts "\t\tDone. Took #{timer} seconds"

      puts "\tCalculating standings"
      10.times do
        visit standings_tournament_players_path(tournament)
        puts "\t\tDone. Took #{timer} seconds"
      end
    end

    # tournament.players.each do |player|
    #   if player.opponents.uniq.length != player.pairings.count
    #     puts "Player #{player.name} (#{player.active? ? :active : :dropped}) had #{player.opponents.uniq.length}/#{player.pairings.count} unique opponents:" # rubocop:disable Layout/LineLength
    #     player.pairings.each do |pairing|
    #       opp = pairing.opponent_for(player)
    #       puts "\t#{pairing.round.number}: #{opp.name}"
    #     end
    #   end
    # end
  end
end
