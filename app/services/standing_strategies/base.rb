# frozen_string_literal: true

module StandingStrategies
  class Base
    attr_reader :stage

    def initialize(stage)
      @stage = stage
    end
  end
end
