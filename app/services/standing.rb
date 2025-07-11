# frozen_string_literal: true

class Standing
  attr_reader :player, :points, :sos, :extended_sos, :bye_points, :corp_points, :runner_points

  delegate :name, :pronouns, :name_with_pronouns, to: :player
  delegate :tournament, :seed_in_stage, to: :player

  def initialize(player, values = {})
    @player = player
    @points = values.fetch(:points, 0) || 0
    @sos = values.fetch(:sos, 0) || 0
    @extended_sos = values.fetch(:extended_sos, 0) || 0
    @bye_points = values.fetch(:bye_points, 0) || 0
    @corp_points = values.fetch(:corp_points, 0) || 0
    @runner_points = values.fetch(:runner_points, 0) || 0
  end

  def <=>(other)
    other.tiebreakers <=> tiebreakers
  end

  def tiebreakers
    [points, -manual_seed, sos, extended_sos]
  end

  def corp_identity
    player.corp_identity_object
  end

  def runner_identity
    player.runner_identity_object
  end

  def manual_seed
    return 0 unless tournament.manual_seed?

    player.manual_seed || Float::INFINITY
  end
end
