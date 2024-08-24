# frozen_string_literal: true

module StandingStrategies
  class Swiss < Base
    def calculate!
      SosCalculator.calculate!(stage)
    end
  end
end
