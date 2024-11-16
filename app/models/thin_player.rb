# frozen_string_literal: true

class ThinPlayer
  def initialize(id, name, active, first_round_bye, points, opponents)
    @id = id
    @name = name
    @active = active
    @first_round_bye = first_round_bye
    @points = points
    @opponents = opponents
    @side_bias = 0
  end

  attr_accessor :id, :name, :active, :first_round_bye, :opponents, :points

  # def ==(other)
  #   @id == other.id
  # end
  # alias eql? ==

  # def hash
  #   [self.class, @id].hash
  # end
end
