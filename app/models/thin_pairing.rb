# frozen_string_literal: true

class ThinPairing
  def initialize(player1, player1_score, player2, player2_score)
    @player1 = player1
    @player1_score = player1_score
    @player2 = player2
    @player2_score = player2_score
  end

  attr_accessor :player1, :player1_score, :player2, :player2_score, :player1_side, :table_number, :fixed_table_number

  def bye?
    player1.nil? or player2.nil?
  end

  def fixed_table_number?
    (!player1.nil? && player1.fixed_table_number) or (!player2.nil? && player2.fixed_table_number)
  end

  def combined_points
    player1.points + player2.points
  end
end
