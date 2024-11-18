# frozen_string_literal: true

module PairingStrategies
  class Base
    attr_reader :round, :random

    delegate :stage, to: :round

    def initialize(round, random = Random)
      @round = round
      @random = random
    end

    def players
      @players ||= round.tournament.build_thin_stuff.select { |_, v| v.active } # stage.players.active
    end
  end
end
