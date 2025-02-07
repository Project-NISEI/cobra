# frozen_string_literal: true

class Tournament < ApplicationRecord
  has_many :players, -> { order(:id) }, dependent: :destroy # rubocop:disable Rails/InverseOf
  belongs_to :user
  has_many :stages, -> { order(:number) }, dependent: :destroy # rubocop:disable Rails/InverseOf
  has_many :rounds

  # TODO(plural): Rename double_elim to elimination
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
    if stage.double_elim? || stage.single_elim?
      cut_decks_open?
    elsif stage.swiss?
      swiss_decks_open?
    else
      false
    end
  end

  def stage_decks_public?(stage)
    if stage.double_elim? || stage.single_elim?
      cut_decks_public?
    elsif stage.swiss?
      swiss_decks_public?
    else
      false
    end
  end

  def corp_counts
    total_players = players.count
    players.group_by(&:corp_identity).map do |id, players|
      [
        Identity.find_or_initialize_by(name: id),
        players.count,
        total_players
      ]
    end.sort_by { |element| element[1] }.reverse # rubocop:disable Style/MultilineBlockChain
  end

  def runner_counts
    total_players = players.count
    players.group_by(&:runner_identity).map do |id, players|
      [
        Identity.find_or_initialize_by(name: id),
        players.count,
        total_players
      ]
    end.sort_by { |element| element[1] }.reverse # rubocop:disable Style/MultilineBlockChain
  end

  def id_and_faction_data
    results = build_id_stats(id)
    results[:cut] = if stages.last.single_elim? || stages.last.double_elim?
                      build_id_stats(id, is_cut: true)
                    else
                      default_id_stats
                    end
    results
  end

  def generate_slug
    self.slug = rand(Integer(36**4)).to_s(36).upcase
    generate_slug if Tournament.exists?(slug:)
  end

  def current_stage
    stages.last
  end

  def single_elim_stage
    stages.find_by format: :single_elim
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

  # Default data structure for the id and faction data, shared between swiss and elimination stages.
  def default_id_stats
    {
      num_players: 0,
      corp: {
        ids: {},
        factions: {}
      },
      runner: {
        ids: {},
        factions: {}
      }
    }
  end

  def build_id_stats(id, is_cut: false)
    results = default_id_stats

    sql = build_id_stats_sql(id, is_cut:)
    ActiveRecord::Base.connection.exec_query(sql).each do |row|
      side = row['side'] == 1 ? :corp : :runner

      # We only need to use 1 side to get the total number of players
      results[:num_players] += row['num_ids'] if side == :corp

      # Only 1 row per id
      results[side][:ids][row['id']] = { count: row['num_ids'], faction: row['faction'] }

      # Multiple rows per faction so we need to sum them up
      results[side][:factions][row['faction']] ||= 0
      results[side][:factions][row['faction']] += row['num_ids']
    end
    results
  end

  def build_id_stats_sql(id, is_cut: false)
    ids_where = if is_cut
                  'p.tournament_id = ? AND p.id IN (SELECT player_id FROM registrations WHERE stage_id IN (' \
                  'SELECT MAX(id) FROM stages WHERE tournament_id = ?))'
                else
                  'p.tournament_id = ?'
                end

    sql = <<~SQL
      WITH corp_ids AS (
        SELECT
          1 AS side,
          COALESCE(corp_ids.name, 'Unspecified') as id,
          COALESCE(corp_ids.faction, 'unspecified') AS faction
        FROM
          players AS p
          LEFT JOIN identities AS corp_ids
            ON p.corp_identity_ref_id = corp_ids.id
        WHERE #{ids_where}
      ),
      runner_ids AS (
          SELECT
            2 AS side,
            COALESCE(runner_ids.name, 'Unspecified') as id,
            COALESCE(runner_ids.faction, 'unspecified') AS faction
          FROM
            players AS p
            LEFT JOIN identities AS runner_ids
              ON p.runner_identity_ref_id = runner_ids.id
          WHERE #{ids_where}
      )
      SELECT side, id, faction, COUNT(*) AS num_ids FROM corp_ids GROUP BY 1,2,3
      UNION ALL
      SELECT side, id, faction, COUNT(*) AS num_ids FROM runner_ids GROUP BY 1,2,3
    SQL

    if is_cut
      ActiveRecord::Base.sanitize_sql([sql, id, id, id, id])
    else
      ActiveRecord::Base.sanitize_sql([sql, id, id])
    end
  end
end
