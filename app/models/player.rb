# frozen_string_literal: true

class Player < ApplicationRecord
  belongs_to :tournament
  belongs_to :user, optional: true
  belongs_to :previous, class_name: 'Player', optional: true
  has_one :next, class_name: 'Player', foreign_key: :previous_id # rubocop:disable Rails/InverseOf
  belongs_to :corp_identity_ref, class_name: 'Identity', optional: true
  belongs_to :runner_identity_ref, class_name: 'Identity', optional: true
  has_many :registrations, dependent: :destroy
  has_many :standing_rows, dependent: :destroy
  has_many :decks, dependent: :destroy

  before_destroy :destroy_pairings
  before_save :set_identities

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

  def side_bias
    @side_bias ||= pairings.reported.reduce(0) do |bias, pairing|
      if pairing.stage.is_cut?
        return bias
      end
      side = pairing.side_for(self)
      bias += 1 if side == :corp
      bias -= 1 if side == :runner

      bias
    end
  end

  def drop!
    update(active: false)
  end

  def eligible_pairings
    pairings.completed
  end

  def seed_in_stage(stage)
    registrations.find_by(stage:)&.seed
  end

  def had_bye?
    pairings.bye.any?
  end

  def corp_identity_object
    if corp_identity_ref
      corp_identity_ref
    elsif corp_identity
      Identity.find_or_initialize_by(name: corp_identity)
    else
      Identity.new
    end
  end

  def runner_identity_object
    if runner_identity_ref
      runner_identity_ref
    elsif runner_identity
      Identity.find_or_initialize_by(name: runner_identity)
    else
      Identity.new
    end
  end

  def corp_deck
    decks.find_by side_id: 'corp'
  end

  def runner_deck
    decks.find_by side_id: 'runner'
  end

  def decks_visible_to(user)
    registrations.any? { |r| r.stage.decks_visible_to(user) }
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

  def set_identities
    self.corp_identity = nil if corp_identity == ''
    self.corp_identity_ref = Identity.find_by(name: corp_identity) if corp_identity
    self.runner_identity = nil if runner_identity == ''
    return unless runner_identity

    self.runner_identity_ref = Identity.find_by(name: runner_identity)
  end
end
