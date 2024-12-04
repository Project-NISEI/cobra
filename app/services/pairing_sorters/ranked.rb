# frozen_string_literal: true

module PairingSorters
  class Ranked
    def self.sort(pairings)
      pairings.sort do |a, b|
        b.combined_points <=> a.combined_points
      end
    end
  end
end
