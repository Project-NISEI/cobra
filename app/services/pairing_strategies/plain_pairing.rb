# frozen_string_literal: true

# PlainPairing is a Plain Ruby model object that provides a Pairing representation
# without the full overhead of the ActiveRecord Pairing object. This exists to keep
# the pairing logic light on memory and object allocation / GC overhead.
module PairingStrategies
  class PlainPairing
    def initialize(player1, player1_score, player2, player2_score)
      @player1 = player1
      @player1_score = player1_score
      @player2 = player2
      @player2_score = player2_score
    end

    attr_accessor :player1, :player1_score, :player2, :player2_score, :player1_side, :table_number

    def players
      [player1, player2].compact
    end

    def bye?
      player1.nil? or player2.nil?
    end

    def fixed_table_number?
      players.any?(&:fixed_table_number?)
    end

    def fixed_table_number
      players.filter(&:fixed_table_number?).map(&:fixed_table_number).min
    end

    def combined_points
      (player1.nil? ? 0 : player1.points) + (player2.nil? ? 0 : player2.points)
    end
  end
end
