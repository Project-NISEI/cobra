# frozen_string_literal: true

# ThinPlayer is a Plain Ruby model object that provides a Pairing representation
# without the full overhead of the ActiveRecord Player object. This exists to keep
# the pairing logic light on memory and object allocation / GC overhead.
class ThinPlayer
  def initialize(id, name, active, first_round_bye, # rubocop:disable Metrics/ParameterLists
                 points: 0, opponents: {}, side_bias: 0, fixed_table_number: nil, had_bye: false)
    @id = id
    @name = name
    @active = active
    @first_round_bye = first_round_bye
    # If the player has a first round bye, they will have had a bye;
    @had_bye = first_round_bye || had_bye
    @points = points
    @opponents = opponents
    @side_bias = side_bias
    @fixed_table_number = fixed_table_number
  end

  attr_accessor :id, :name, :active, :first_round_bye, :opponents, :points, :side_bias, :had_bye, :fixed_table_number

  def add_opponent(opponent_id, side)
    @opponents[opponent_id] = [] unless @opponents.key?(opponent_id)
    @opponents[opponent_id] << side
  end

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
