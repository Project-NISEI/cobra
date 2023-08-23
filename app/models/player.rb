class Player < ApplicationRecord
  include Pairable

  belongs_to :tournament
  belongs_to :user, optional: true
  belongs_to :previous, class_name: 'Player', optional: true
  has_one :next, class_name: 'Player', foreign_key: :previous_id
  has_many :registrations, dependent: :destroy
  has_many :standing_rows, dependent: :destroy
  has_many :decks, dependent: :destroy

  before_destroy :destroy_pairings
  before_save :handle_blank_identities

  scope :active, -> { where(active: true) }
  scope :dropped, -> { where(active: false) }
  scope :with_first_round_bye, -> { where(first_round_bye: true) }

  def pairings
    Pairing.for_player(self)
  end

  def non_bye_pairings
    pairings.non_bye
  end

  def opponents
    pairings.map { |p| p.opponent_for(self) }
  end

  def non_bye_opponents
    non_bye_pairings.map { |p| p.opponent_for(self) }
  end

  def points
    @points ||= pairings.reported.sum { |pairing| pairing.score_for(self) }
  end

  def sos_earned
    @sos_earned ||= non_bye_pairings.reported.sum { |pairing| pairing.score_for(self) }
  end

  def drop!
    update(active: false)
  end

  def eligible_pairings
    pairings.completed
  end

  def seed_in_stage(stage)
    registrations.find_by(stage: stage)&.seed
  end

  def had_bye?
    pairings.bye.any?
  end

  def corp_identity_object
    Identity.find_or_initialize_by(name: corp_identity)
  end

  def runner_identity_object
    Identity.find_or_initialize_by(name: runner_identity)
  end

  def corp_deck
    decks.find_by side_id: 'corp'
  end

  def runner_deck
    decks.find_by side_id: 'runner'
  end

  def cut_decks_visible_to(user)
    stage = tournament.double_elim_stage
    unless registrations.find_by(stage: stage)
      return false
    end
    if tournament.open_list_cut? && (user == tournament.user || stage.users.exists?(user&.id))
      true
    else
      tournament.public_list_cut?
    end
  end

  def name_with_pronouns
    if pronouns?
      "#{name} (#{pronouns})"
    else
      name
    end
  end

  private

  def destroy_pairings
    pairings.destroy_all
  end

  def handle_blank_identities
    if corp_identity == ''
      self.corp_identity = nil
    end
    if runner_identity == ''
      self.runner_identity = nil
    end
  end
end
