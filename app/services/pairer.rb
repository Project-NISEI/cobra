# frozen_string_literal: true

class Pairer
  attr_reader :round, :random

  delegate :stage, to: :round

  def initialize(round, random = Random)
    @round = round
    @random = random
  end

  def pair!
    strategy.new(round, random).pair!
  end

  private

  def strategy
    return PairingStrategies::Swiss unless %w[swiss double_elim single_elim single_sided_swiss].include? stage.format

    "PairingStrategies::#{stage.format.camelize}".constantize
  end
end
