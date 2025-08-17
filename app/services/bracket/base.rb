# frozen_string_literal: true

module Bracket
  class Base
    include Engine

    attr_reader :stage

    delegate :seed, to: :stage

    def initialize(stage = nil)
      return unless stage

      @stage = stage
      @pairings = stage.rounds.select(&:completed?)
                       .map(&:pairings).flatten
      @seed_by_player = stage.registrations.map { |r| [r.player_id, r.seed] }.to_h
    end

    def pair(number)
      games_for_round(number).map do |g|
        {
          table_number: g[:number],
          player1: g[:player1].call(self),
          player2: g[:player2].call(self)
        }
      end
    end

    def winner(number)
      pairing(number).try(:winner)
    end

    def loser(number)
      pairing(number).try(:loser)
    end

    def winner_if_also_winner(number, other)
      w = winner(number)

      w if w == winner(other)
    end

    def loser_if_also_winner(number, other)
      l = loser(number)

      l if l == winner(other)
    end

    def seed_of(players, pos)
      p = players.map do |lam|
        lam.call(self)
      end
      p = p.tap do |x|
        return nil unless x.all?
      end
      p.sort_by do |x|
        @seed_by_player[x.id]
      end[pos - 1]
    end

    def standings
      s = self.class::STANDINGS.map do |lam|
        if lam.is_a? Array
          lam.map { |l| l.call(self) }.compact.try(:first)
        else
          lam.call(self)
        end
      end
      s.map { |p| Standing.new(p) }
    end

    private

    def pairing(number)
      @pairings.find { |i| i.table_number == number }
    end
  end
end
