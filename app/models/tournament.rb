# frozen_string_literal: true

class Tournament < ApplicationRecord
  has_many :players, -> { order(:id) }, dependent: :destroy # rubocop:disable Rails/InverseOf
  belongs_to :user
  has_many :stages, -> { order(:number) }, dependent: :destroy # rubocop:disable Rails/InverseOf
  has_many :rounds

  enum :stage, { swiss: 0, double_elim: 1 }

  enum :cut_deck_visibility, { cut_decks_private: 0, cut_decks_open: 1, cut_decks_public: 2 }

  enum :swiss_deck_visibility, { swiss_decks_private: 0, swiss_decks_open: 1, swiss_decks_public: 2 }

  enum :swiss_format, { double_sided: 0, single_sided: 1 }

  delegate :new_round!, to: :current_stage
  delegate :pair_new_round!, to: :current_stage

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true # rubocop:disable Rails/UniqueValidationWithoutIndex

  before_validation :generate_slug, on: :create, unless: :slug
  before_create :default_date, unless: :date
  after_create :create_stage

  def cut_to!(format, number)
    previous_stage = current_stage
    stages.create!(
      format:,
      number: previous_stage.number + 1
    ).tap do |stage|
      previous_stage.top(number).each_with_index do |player, i|
        stage.registrations.create!(
          player:,
          seed: i + 1
        )
      end
    end
  end

  def lock_player_registrations!
    players.active.update(registration_locked: true)
    update(all_players_unlocked: false, any_player_unlocked: false)
  end

  def unlock_player_registrations!
    players.active.update(registration_locked: false)
    update(all_players_unlocked: true, any_player_unlocked: true)
  end

  def close_registration!
    update(registration_closed: true)
    lock_player_registrations!
  end

  def open_registration!
    update(registration_closed: false)
  end

  def registration_open?
    self_registration? && !registration_closed?
  end

  def registration_unlocked?
    self_registration? && (!registration_closed? || unlocked_players.count.positive?)
  end

  def stage_decks_open?(stage)
    if stage.double_elim?
      cut_decks_open?
    elsif stage.swiss?
      swiss_decks_open?
    else
      false
    end
  end

  def stage_decks_public?(stage)
    if stage.double_elim?
      cut_decks_public?
    elsif stage.swiss?
      swiss_decks_public?
    else
      false
    end
  end

  def corp_counts
    players.group_by(&:corp_identity).map do |id, players|
      [
        Identity.find_or_initialize_by(name: id),
        players.count
      ]
    end.sort_by(&:last).reverse
  end

  def runner_counts
    players.group_by(&:runner_identity).map do |id, players|
      [
        Identity.find_or_initialize_by(name: id),
        players.count
      ]
    end.sort_by(&:last).reverse
  end

  def generate_slug
    self.slug = rand(Integer(36**4)).to_s(36).upcase
    generate_slug if Tournament.exists?(slug:)
  end

  def current_stage
    stages.last
  end

  def double_elim_stage
    stages.find_by format: :double_elim
  end

  def unlocked_players
    players.active.where('registration_locked IS NOT TRUE')
  end

  def locked_players
    players.active.where('registration_locked IS TRUE')
  end

  def registration_lock_description
    if registration_closed?
      if all_players_unlocked?
        'closed, unlocked'
      elsif any_player_unlocked?
        'closed, part unlocked'
      else
        'closed'
      end
    elsif all_players_unlocked?
      'open'
    elsif any_player_unlocked?
      'open, part locked'
    else
      'open, all locked'
    end
  end

  def decks_visibility_description
    "swiss #{swiss_decks_visibility_desc}, cut #{cut_decks_visibility_desc}"
  end

  def swiss_decks_visibility_desc
    if swiss_decks_public?
      'public'
    elsif swiss_decks_open?
      'open'
    else
      'private'
    end
  end

  def cut_decks_visibility_desc
    if cut_decks_public?
      'public'
    elsif cut_decks_open?
      'open'
    else
      'private'
    end
  end

  def self.min_visibility_swiss_or_cut(swiss, cut)
    swiss_visibility = Tournament.swiss_deck_visibilities[swiss]
    cut_visibility = Tournament.cut_deck_visibilities[cut]
    if cut_visibility < swiss_visibility
      Tournament.swiss_deck_visibilities.invert[cut_visibility]
    else
      swiss
    end
  end

  def self.max_visibility_cut_or_swiss(cut, swiss)
    cut_visibility = Tournament.cut_deck_visibilities[cut]
    swiss_visibility = Tournament.swiss_deck_visibilities[swiss]
    if swiss_visibility > cut_visibility
      Tournament.cut_deck_visibilities.invert[swiss_visibility]
    else
      cut
    end
  end

  def self.streaming_opt_out_notice
    'Should we include your games in video coverage of this event? ' \
      'Note: During a top cut it may not be possible to exclude you from coverage.'
  end

  def self.registration_consent_notice
    'Your name, pronouns and Netrunner deck identities will be publicly visible on this ' \
      'website. If you submit decklists they will be shared with the organiser. If you enter a round with open ' \
      'decklists, they may be shared with participants or made public.'
  end

  def build_thin_stuff # rubocop:disable Metrics/MethodLength
    # SQL to use as input for building up scoring and pairing data efficiently.
    _old_completed_pairings_sql = "
      SELECT
        p.id,
        p.side,
        p.player1_id,
        p1.active as player1_active,
        p1.name as player1_name,
        p1.first_round_bye as player1_first_round_bye,
        COALESCE(p.score1, 0) AS score1,
        p.player2_id,
        p2.active as player2_active,
        p2.name as player2_name,
        p2.first_round_bye as player2_first_round_bye,
        COALESCE(p.score2, 0) AS score2
      FROM
        pairings AS p
        INNER JOIN rounds AS r ON p.round_id = r.id
        INNER JOIN stages AS s ON r.stage_id = s.id
        LEFT JOIN players AS p1 ON p.player1_id = p1.id
        LEFT JOIN players AS p2 ON p.player2_id = p2.id
      WHERE r.completed
        AND s.tournament_id = #{id}"

    player_summary_sql = "
WITH player1_pairings AS (
    SELECT p.round_id,
        p.player1_id AS player_id,
        p.player1_id IS NULL
        OR p.player2_id IS NULL AS is_bye,
        CASE
            WHEN p.side = 1 THEN 'corp'
            ELSE 'runner'
        END AS side,
        p.score1 AS score,
        p.player2_id AS opponent_id,
        CASE
            WHEN p.side = 1 THEN 'runnner'
            ELSE 'corp'
        END AS opponent_side
    FROM pairings AS p
        INNER JOIN rounds AS r ON p.round_id = r.id
    WHERE r.tournament_id = #{id} AND r.completed
),
player2_pairings AS (
    SELECT p.round_id,
        p.player2_id AS player_id,
        p.player2_id IS NULL
        OR p.player2_id IS NULL AS is_bye,
        -- flip the logic since this is player 2
        CASE
            WHEN p.side = 1 THEN 'runner'
            ELSE 'corp'
        END AS side,
        p.score2 AS score,
        p.player1_id AS opponent_id,
        CASE
            WHEN p.side = 1 THEN 'corp'
            ELSE 'runner'
        END AS opponent_side
    FROM pairings AS p
        INNER JOIN rounds AS r ON p.round_id = r.id
    WHERE r.tournament_id = #{id} AND r.completed
),
unified_pairings AS (
    SELECT *
    FROM player1_pairings
    UNION ALL
    SELECT *
    FROM player2_pairings
)
SELECT p.id as player_id,
    p.name as player_name,
    p.active,
    p.first_round_bye,
    up.is_bye,
    up.side,
    COALESCE(up.score, 0) AS score,
    up.opponent_id,
    up.opponent_side
FROM players AS p
    LEFT JOIN unified_pairings AS up ON p.id = up.player_id
WHERE p.tournament_id = #{id}
ORDER BY p.id, up.round_id;
    "
    results = ActiveRecord::Base.connection.select_all(player_summary_sql)

    player_summary = {}
    results.each do |p|
      player_id = p['player_id']
      unless player_summary.key?(player_id)
        player_summary[player_id] =
          { name: p['player_name'], active: p['active'], first_round_bye: p['first_round_bye'],
            points: 0, side_bias: 0, opponents: {} }
      end

      summary = player_summary[player_id]
      summary[:points] += p['score']

      unless p['is_bye'] || p['opponent_id'].nil?
        if p['side'] == 'corp'
          summary[:side_bias] += 1
        else
          summary[:side_bias] -= 1
        end
      end

      # Set opponents iff there is no bye in this pairing
      next if p['is_bye'] || p['opponent_id'].nil?

      summary[:opponents][p['opponent_id']] = [] unless summary[:opponents].key?(p['opponent_id'])
      summary[:opponents][p['opponent_id']] << p['side']
    end

    thin_players = {}
    player_summary.each do |player_id, data|
      thin_players[player_id] = ThinPlayer.new(
        player_id, data[:name], data[:active], data[:first_round_bye], data[:points],
        data[:opponents], data[:side_bias]
      )
    end

    thin_players
  end

  private

  def default_date
    self.date = Date.current
  end

  def create_stage
    stages.create(
      number: 1,
      format: single_sided? ? :single_sided_swiss : :swiss
    )
  end
end
