module PairingStrategies
  class Base
    attr_reader :round, :random
    delegate :stage, to: :round

    def initialize(round, random = Random)
      @round = round
      @random = random
    end

    def players
      @players ||= stage.players.active
    end
  end
end
