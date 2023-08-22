class Stage < ApplicationRecord
  belongs_to :tournament, touch: true
  has_many :rounds, dependent: :destroy
  has_many :registrations, dependent: :destroy
  has_many :players, through: :registrations
  has_many :users, through: :players
  has_many :standing_rows, dependent: :destroy

  delegate :top, to: :standings

  enum format: {
    swiss: 0,
    double_elim: 1
  }

  def pair_new_round!
    number = (rounds.pluck(:number).max || 0) + 1
    rounds.create(number: number, length_minutes: default_round_minutes).tap do |round|
      round.pair!
    end
  end

  def standings
    Standings.new(self)
  end

  def eligible_pairings
    rounds.complete.map(&:pairings).flatten
  end

  def seed(number)
    registrations.find_by(seed: number).try(:player)
  end

  def single_sided?
    double_elim?
  end

  def default_round_minutes
    if double_elim?
      40
    else
      65
    end
  end

  def cache_standings!
    standing_rows.destroy_all
    standings.each_with_index do |standing, i|
      standing_rows.create(
        position: i + 1,
        player: standing.player,
        points: standing.points,
        sos: standing.sos,
        extended_sos: standing.extended_sos,
        corp_points: standing.corp_points,
        runner_points: standing.runner_points
      )
    end
  end
end
