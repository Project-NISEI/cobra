# frozen_string_literal: true

class ThinPairing
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

    [ftn(player1), ftn(player2)].min

    # fixed_table_1 = 999_999
    # fixed_table_1 = player1.fixed_table_number if !player1.nil? && !player1.fixed_table_number.nil?
    # (player1.nil? ? 999_999 : player1.fixed_table_number).floor(player2.nil? ? 999_999 : player2.fixed_table_number)
  end

  def combined_points
    (player1.nil? ? 0 : player1.points) + (player2.nil? ? 0 : player2.points)
  end

  private

  def ftn(player)
    return 999_999 if player.nil? || player&.fixed_table_number.nil?

    player.fixed_table_number
  end
end
