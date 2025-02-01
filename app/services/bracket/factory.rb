# frozen_string_literal: true

module Bracket
  class Factory
    def self.bracket_for(num_players, single_elim: false)
      raise 'bracket size not supported' unless [3, 4, 8, 16].include? num_players

      prefix = 'Top'
      prefix = 'SingleElimTop' if single_elim || num_players == 3
      Rails.logger.info "Bracket class is Bracket::#{prefix}#{num_players}"
      "Bracket::#{prefix}#{num_players}".constantize
    end
  end
end
