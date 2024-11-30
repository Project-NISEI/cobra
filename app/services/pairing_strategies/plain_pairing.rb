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

    def bye?
      player1.nil? or player2.nil?
    end

    def fixed_table_number?
      (!player1.nil? && player1.fixed_table_number) or (!player2.nil? && player2.fixed_table_number)
    end

    def fixed_table_number
      return nil unless fixed_table_number?

      [big_num_if_nil(player1), big_num_if_nil(player2)].min
    end

    def combined_points
      (player1.nil? ? 0 : player1.points) + (player2.nil? ? 0 : player2.points)
    end

    private

    # Use a Very Large Number if the player is nil to aid picking the lowest (numerical) table number for fixed tables.
    def big_num_if_nil(player)
      return 999_999 if player.nil? || player&.fixed_table_number.nil?

      player.fixed_table_number
    end
  end
end
