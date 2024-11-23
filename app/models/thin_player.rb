# frozen_string_literal: true

class ThinPlayer
  def initialize(id, name, active, first_round_bye, points, opponents, side_bias, had_bye, fixed_table_number = nil) # rubocop:disable Metrics/ParameterLists
    @id = id
    @name = name
    @active = active
    @first_round_bye = first_round_bye
    @points = points
    @opponents = opponents
    @side_bias = side_bias
    @had_bye = had_bye
    @fixed_table_number = fixed_table_number
  end

  attr_accessor :id, :name, :active, :first_round_bye, :opponents, :points, :side_bias, :had_bye, :fixed_table_number

  def unpairable_opponents
    opponents.keys + (@had_bye ? [SwissImplementation::Bye] : [])
  end

  def ==(other)
    return false if other.class != self.class

    @id == other.id &&
      @name == other.name &&
      @active == other.active &&
      @first_round_bye == other.first_round_bye &&
      @opponents == other.opponents &&
      @points == other.points &&
      @side_bias == other.side_bias
  end
  alias eql? ==

  def hash
    [self.class, @id].hash
  end
end
