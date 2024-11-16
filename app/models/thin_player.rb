class ThinPlayer
  def initialize(id, name)
    @id = id
    @name = name
    @opponents = []
    @points = 0
  end

  attr_accessor :id, :name, :opponents, :points

  def ==(other)
    @id == other.id
  end
  alias eql? ==

  def hash
    [self.class, @id].hash
  end
end
