class Pairing < ApplicationRecord
  belongs_to :round, touch: true
  belongs_to :player1, class_name: 'Player', optional: true
  belongs_to :player2, class_name: 'Player', optional: true
  has_one :tournament, through: :round
  has_one :stage, through: :round

  scope :non_bye, -> { where('player1_id IS NOT NULL AND player2_id IS NOT NULL') }
  scope :bye, -> { where('player1_id IS NULL OR player2_id IS NULL') }
  scope :reported, -> { where.not(score1: nil, score2: nil) }
  scope :completed, -> { joins(:round).where('rounds.completed = ?', true) }
  scope :for_stage, ->(stage) { joins(:round).where(rounds: { stage: stage }) }

  before_save :normalise_scores_before_save
  after_update :cache_standings!, if: Proc.new { round.completed? }
  delegate :cache_standings!, to: :stage

  enum side: {
    player1_is_corp: 1,
    player1_is_runner: 2
  }

  def self.for_player(player)
    where(player1: player).or(where(player2: player))
  end

  def players
    [player1, player2]
  end

  def player1
    super || NilPlayer.new
  end

  def player2
    super || NilPlayer.new
  end

  def reported?
    score1.present? || score2.present?
  end

  def score_for(player)
    return unless players.include? player

    player1 == player ? score1 : score2
  end

  def opponent_for(player)
    return unless players.include? player

    player1 == player ? player2 : player1
  end

  def winner
    return if score1 == score2

    score1 > score2 ? player1 : player2
  end

  def loser
    return if score1 == score2

    score1 < score2 ? player1 : player2
  end

  def player1_side
    return unless side

    player1_is_corp? ? :corp : :runner
  end

  def player2_side
    return unless side

    player1_is_corp? ? :runner : :corp
  end

  def decks_visible_to(user)
    if !stage.single_sided? || side.nil?
      return false
    end
    if tournament.stage_decks_open?(stage) && (user == tournament.user || stage.users.exists?(user&.id))
      true
    else
      tournament.stage_decks_public?(stage)
    end
  end

  def player1_deck
    if side.nil?
      nil
    else
      player1_is_corp? ? player1.corp_deck : player1.runner_deck
    end
  end

  def player2_deck
    if side.nil?
      nil
    else
      player1_is_runner? ? player2.corp_deck : player2.runner_deck
    end
  end

  def side_for(player)
    return unless players.include? player

    player1 == player ? player1_side : player2_side
  end

  private

  def normalise_scores_before_save
    # Handle score presets set as corp & runner scores
    combine_separate_side_scores
    # Handle custom scores set directly
    ensure_custom_scores_complete
  end

  def combine_separate_side_scores
    return unless (score1_corp.present? && score1_corp > 0) ||
      (score1_runner.present? && score1_runner > 0) ||
      (score2_corp.present? && score2_corp > 0) ||
      (score2_runner.present? && score2_runner > 0)

    self.score1 = (score1_corp || 0) + (score1_runner || 0)
    self.score2 = (score2_corp || 0) + (score2_runner || 0)
  end

  def ensure_custom_scores_complete
    return unless score1.present? || score2.present?

    self.score1 = score1 || 0
    self.score2 = score2 || 0
  end
end
