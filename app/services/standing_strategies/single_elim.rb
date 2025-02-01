# frozen_string_literal: true

module StandingStrategies
  class SingleElim < Base
    def calculate!
      bracket.new(stage).standings
    end

    private

    def bracket
      Bracket::Factory.bracket_for stage.players.count, single_elim: true
    end
  end
end
