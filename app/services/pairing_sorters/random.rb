# frozen_string_literal: true

module PairingSorters
  class Random
    def self.sort(pairings)
      pairings.shuffle
    end
  end
end
