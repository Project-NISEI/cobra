# frozen_string_literal: true

module PairingSorters
  class Ranked
    def self.sort(pairings, player_summary = nil)
      if player_summary.nil?
        pairings.sort do |a, b|
          b.combined_points <=> a.combined_points
        end
      else
        pairings.sort do |a, b|
          (points(player_summary, b.player1_id) + points(player_summary, b.player2_id)) <=>
            (points(player_summary, a.player1_id) + points(player_summary, a.player2_id))
        end
      end
    end

    def self.points(player_summary, player_id)
      if player_summary.key?(player_id)
        player_summary[player_id].points
      else
        0
      end
    end
  end
end
