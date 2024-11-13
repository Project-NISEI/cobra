class ThinPlayer
  def initialize(id, name, opponents, points)
    @id = id
    @name = name
    @opponents = opponents
    @points = points
  end

  attr_accessor :id, :name, :opponents, :points
end
