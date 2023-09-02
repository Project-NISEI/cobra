class Tournament < ApplicationRecord
  has_many :players, -> { order(:id) }, dependent: :destroy
  belongs_to :user
  has_many :stages, -> { order(:number) }, dependent: :destroy
  has_many :rounds, through: :stages

  enum stage: {
    swiss: 0,
    double_elim: 1
  }

  enum cut_deck_visibility: {
    cut_decks_private: 0,
    cut_decks_open: 1,
    cut_decks_public: 2
  }

  enum swiss_deck_visibility: {
    swiss_decks_private: 0,
    swiss_decks_open: 1,
    swiss_decks_public: 2
  }

  delegate :pair_new_round!, to: :current_stage

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  before_validation :generate_slug, on: :create, unless: :slug
  before_create :default_date, unless: :date
  after_create :create_stage

  def cut_to!(format, number)
    previous_stage = current_stage
    stages.create!(
      format: format,
      number: previous_stage.number + 1
    ).tap do |stage|
      previous_stage.top(number).each_with_index do |player, i|
        stage.registrations.create!(
          player: player,
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
    self.slug = rand(Integer(36 ** 4)).to_s(36).upcase
    generate_slug if Tournament.exists?(slug: slug)
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
    else
      if all_players_unlocked?
        'open'
      elsif any_player_unlocked?
        'open, part locked'
      else
        'open, all locked'
      end
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
    'Should we include your Swiss games in video coverage of this event? ' \
      'Note: During a top cut your games may be included in video coverage.'
  end

  def self.registration_consent_notice
    'Your name, pronouns and Netrunner deck identities will be publicly visible on this ' \
      'website. If you submit decklists they will be shared with the organiser. If you enter a round with open ' \
      'decklists, they may be publicly visible.'
  end

  private

  def default_date
    self.date = Date.current
  end

  def create_stage
    stages.create(
      number: 1,
      format: :swiss
    )
  end
end
