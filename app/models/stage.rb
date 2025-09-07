# frozen_string_literal: true

class Stage < ApplicationRecord
  belongs_to :tournament, touch: true
  has_many :rounds, dependent: :destroy
  has_many :registrations, dependent: :destroy
  has_many :players, through: :registrations
  has_many :users, through: :players
  has_many :standing_rows, dependent: :destroy

  delegate :top, to: :standings

  enum :format, {
    swiss: 0, # Double-Sided Swiss
    double_elim: 1,
    single_sided_swiss: 2,
    single_elim: 3
  }

  def pair_new_round!
    new_round!.tap(&:pair!)
  end

  def new_round!
    number = (rounds.pluck(:number).max || 0) + 1
    rounds.create(number:, tournament_id:, length_minutes: default_round_minutes)
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

  def any_swiss?
    swiss? || single_sided_swiss?
  end

  def single_sided?
    single_sided_swiss? || elimination?
  end

  def elimination?
    single_elim? || double_elim?
  end

  def cut?
    double_elim? || single_elim?
  end

  def default_round_minutes
    if single_sided?
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
        runner_points: standing.runner_points,
        bye_points: standing.bye_points || 0
      )
    end
  end

  def decks_open?
    tournament.stage_decks_open?(self)
  end

  def decks_public?
    tournament.stage_decks_public?(self)
  end

  def decks_visible_to(user)
    if decks_open?
      user == tournament.user || users.exists?(user&.id)
    else
      decks_public?
    end
  end
end
