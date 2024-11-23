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

  # Returns a list of opponent player ids and the Bye sentinel if present.
  # Used by SwissImplementation to aid pairing logic in SingleSidedSwiss for byes and previous opponents.
  def unpairable_opponents
    opponents.keys + (@had_bye ? [SwissImplementation::Bye] : [])
  end

  # Value equality
  def ==(other)
    return false if other.class != self.class

    @id == other.id &&
      @name == other.name &&
      @active == other.active &&
      @first_round_bye == other.first_round_bye &&
      @opponents == other.opponents &&
      @points == other.points &&
      @side_bias == other.side_bias &&
      @had_bye == other.had_bye &&
      @fixed_table_number == other.fixed_table_number
  end
  alias eql? ==

  # Override hash function to focus on the id.  This is fragile in the general case,
  # but OK in practice because player IDs are unique.
  def hash
    [self.class, @id].hash
  end
end
