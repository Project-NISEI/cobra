# frozen_string_literal: true

# Set a profile=1 env var to record profiles to feed into analysis tools and flame graphs.
# Example: profile=1 bundle exec rspec spec/load_test.rb
require 'ruby-prof-flamegraph'

RSpec.describe 'load testing' do
  ROUNDS = 10 # rubocop:disable Lint/ConstantDefinitionInBlock,RSpec/LeakyConstantDeclaration
  PLAYERS = 150 # rubocop:disable Lint/ConstantDefinitionInBlock,RSpec/LeakyConstantDeclaration

  let(:tournament) { create(:tournament, swiss_format: :single_sided) }

  def timer
    (Time.zone.now - (@start || Time.zone.now)).seconds.tap do
      @start = Time.zone.now
    end
  end

  it 'can handle load' do
    profiles = []
    timer
    sign_in tournament.user
    puts 'Creating players'
    PLAYERS.times { create(:player, tournament:) }

    puts "Side bias for first player is #{tournament.players[0].side_bias}"
    expect(tournament.players.count).to equal(PLAYERS)
    puts "\tDone. Took #{timer} seconds"

    active_players = PLAYERS
    ROUNDS.times do |i|
      puts "Round #{i + 1}"

      Rails.logger.info "Pairing Round #{i + 1} start"
      puts "\tPairing #{tournament.players.active.count} players"
      round = nil

      if ENV['profile']
        profiles << RubyProf.profile do
          round = tournament.pair_new_round!
        end
      else
        round = tournament.pair_new_round!
      end

      puts "\t\tDone. Took #{timer} seconds to pair #{tournament.players.active.count} players"
      Rails.logger.info "Pairing Round #{i + 1} end"
      expect(round.pairings.count).to eq((active_players / 2.0).ceil)
      players = round.pairings.map(&:players).flatten
      expect(players.map(&:id) - [nil]).to match_array(tournament.players.active.map(&:id))
      expect(players.select { |p| p.is_a? NilPlayer }.length).to be < 2

      puts "\tGenerating results"
      round.pairings.each do |p|
        # score = [[6, 0], [4, 1], [3, 3], [0, 6]].sample
        score = [[3, 0], [0, 3], [1, 1]].sample
        # visit tournament_rounds_path(tournament)
        p.update(score1: score.first, score2: score.last)
      end
      tournament.players.active.shuffle.take(3).each { |p| p.update(active: false) }
      active_players -= 3
      round.update(completed: true)
      puts "\t\tDone. Took #{timer} seconds"

      puts "\tCalculating standings"
      2.times do
        visit standings_tournament_players_path(tournament)
        puts "\t\tDone. Took #{timer} seconds"
      end

      side_bias = { -1 => 0, 0 => 0, 1 => 0 }
      tournament.players.active.each do |p|
        side_bias[p.side_bias] = 0 unless side_bias.key?(p.side_bias)
        side_bias[p.side_bias] += 1
      end
      puts "Round #{i + 1} side bias: #{side_bias.inspect}"
    end

    profiles.length.times do |i|
      File.open("stack-file-#{i + 1}", 'w+') do |file|
        RubyProf::FlameGraphPrinter.new(profiles[i]).print(file)
      end
    end
  end
end
