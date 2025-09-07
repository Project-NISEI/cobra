# frozen_string_literal: true

class PlayersController < ApplicationController
  before_action :set_tournament
  before_action :set_player, only: %i[update destroy drop reinstate
                                      lock_registration unlock_registration registration view_decks]

  def index
    authorize @tournament, :update?

    @players = @tournament.players.active.sort_by { |p| p.name.downcase || '' }
    @dropped = @tournament.players.dropped.sort_by { |p| p.name.downcase || '' }
  end

  def download_decks
    authorize @tournament, :update?
    render json: @tournament.players
                            .sort_by(&:name)
                            .flat_map { |p| p.decks.sort_by(&:side_id) }
                            .map { |d| d.as_view(current_user) }
  end

  def download_streaming
    authorize @tournament, :update?
    render json: @tournament.players.active
                            .sort_by(&:name)
                            .map { |p|
                   {
                     name: p.name_with_pronouns,
                     include_in_stream: p.include_in_stream?
                   }
                 }
  end

  def create
    authorize Player
    if @tournament.registration_open?
      authorize @tournament, :show?
    else
      authorize @tournament, :update?
    end

    params = player_params
    params[:user_id] = current_user.id unless organiser_view?

    player = @tournament.players.create(params.except(:corp_deck, :runner_deck))
    @tournament.current_stage.players << player unless @tournament.current_stage.nil?
    @tournament.update(any_player_unlocked: true,
                       all_players_unlocked: @tournament.locked_players.count.zero?)

    if player.user_id
      if @tournament.nrdb_deck_registration?
        redirect_to registration_tournament_path(@tournament)
      else
        redirect_to tournament_path(@tournament)
      end
    else
      redirect_to tournament_players_path(@tournament)
    end
  end

  def update
    authorize @player

    if organiser_view?
      if params.require(:player)[:registration_view]
        redirect_to registration_tournament_player_path(@tournament, @player)
      else
        redirect_to tournament_players_path(@tournament)
      end
      update = player_params
    else
      redirect_to tournament_path(@tournament)
      update = if @player.registration_locked?
                 params.require(:player).permit(:include_in_stream)
               else
                 player_params
               end
      update[:user_id] = current_user.id
    end

    @player.update(update.except(:corp_deck, :runner_deck))
    return unless @tournament.nrdb_deck_registration?

    save_deck(update, :corp_deck, 'corp')
    save_deck(update, :runner_deck, 'runner')
  end

  def save_deck(params, param, side)
    return unless params.key?(param)

    begin
      request = JSON.parse(params[param])
    rescue StandardError
      @player.decks.destroy_by(side_id: side)
      return
    end
    details = request['details']
    return if details['user_id'] && details['user_id'] != current_user.id

    details.keep_if { |key| Deck.column_names.include? key }
    details['side_id'] = side
    details['user_id'] = current_user.id
    @player.decks.destroy_by(side_id: side)
    deck = @player.decks.create(details)
    deck.cards.create(request['cards'])
  end

  def destroy
    authorize @tournament, :update?

    @player.destroy
    @tournament.update(any_player_unlocked: @tournament.unlocked_players.count.positive?,
                       all_players_unlocked: @tournament.locked_players.count.zero?)

    redirect_to tournament_players_path(@tournament)
  end

  def standings
    authorize @tournament, :show?
  end

  def view_standings
    authorize @tournament, :show?
  end

  def standings_data
    authorize @tournament, :show?

    stages = @tournament.stages.includes(
      rounds: [pairings: %i[player1 player2]],
      registrations: [player: [:user, :corp_identity_ref, :runner_identity_ref, { registrations: [:stage] }]],
      standing_rows: [player: [:user, :corp_identity_ref, :runner_identity_ref, { registrations: [:stage] }]]
    )
    elimination = stages.select(&:double_elim?).first
    elimination = stages.select(&:single_elim?).first if elimination.nil?
    render json: {
      is_player_meeting: stages.all? { |stage| stage.rounds.empty? },
      manual_seed: @tournament.manual_seed?,
      stages: stages.reverse.map do |stage|
        Rails.logger.info "Stage decks_visible_to is #{stage.decks_visible_to(current_user)}"
        {
          format: stage.format,
          rounds_complete: stage.rounds.select(&:completed?).count,
          any_decks_viewable: stage.decks_visible_to(current_user) ||
            (elimination&.decks_visible_to(current_user) ? true : false),
          standings: render_standings_for_stage(stage)
        }
      end
    }
  end

  def new_standings_data
    authorize @tournament, :show?

    sql = ActiveRecord::Base.sanitize_sql([
                                            'SELECT * FROM standings_data_view WHERE tournament_id = ? ORDER BY stage_number DESC, position', @tournament.id
                                          ])
    rows = ActiveRecord::Base.connection.exec_query(sql).to_a

    is_player_meeting = false
    tournament_manual_seed = false
    any_decks_viewable = false

    stages_map = {}
    elimination_position = 0
    rows.each do |r|
      is_player_meeting = true if r['is_player_meeting']
      tournament_manual_seed = r['tournament_manual_seed']

      stages_map[r['stage_number']] = {} unless stages_map.key?(r['stage_number'])
      stage = stages_map[r['stage_number']]
      stage[:format] = Stage.formats.invert[r['stage_format']]
      stage[:num_rounds_completed] = r['num_rounds_completed']

      stage[:elimination] = [Stage.formats['single_elim'], Stage.formats['double_elim']].include?(r['stage_format'])

      stage_decks_open =
        if stage[:elimination]
          Tournament.cut_deck_visibilities[:cut_decks_open] == r['cut_deck_visibility']
        else
          Tournament.swiss_deck_visibilities[:swiss_deck_open] == r['swiss_deck_visibility']
        end
      stage_decks_public =
        if stage[:elimination]
          Tournament.cut_deck_visibilities[:cut_decks_public] == r['cut_deck_visibility']
        else
          Tournament.swiss_deck_visibilities[:swiss_decks_public] == r['swiss_deck_visibility']
        end

      stage[:stage_decks_open] = stage_decks_open
      stage[:stage_decks_public] = stage_decks_public

      stage[:num_rounds_completed] = r['num_rounds_completed']

      # this will be set to true if any user in the stage has visible decks, checked in the loop below.
      stage[:any_decks_viewable] = false

      stage[:standings] = [] unless stage.key?(:standings)

      view_player_decks =
        if stage[:stage_decks_open] && current_user
          [r['tournament_user_id'], r['player_user_id']].include?(current_user&.id)
        else
          stage[:stage_decks_public]
        end
      any_decks_viewable = true if view_player_decks

      player = {}
      # Swiss rounds have more detailed player records than elimination rounds
      if stage[:elimination]
        elimination_position += 1
        player = {
          player: nil,
          policy: {
            view_decks: false
          },
          position: elimination_position,
          seed: (r['seed'] if r['position']),
        }
        if r['player_name'].present?
          player[:position] = r['position']
          player[:player] = {
            id: r['player_id'],
            active: r['player_active'],
            name_with_pronouns: "#{r['player_name']}#{r['player_pronouns'].present? ? " (#{r['player_pronouns']})" : ''}",
            corp_id: {
              name: r['corp_id_name'],
              faction: r['corp_id_faction']
            },
            runner_id: {
              name: r['runner_id_name'],
              faction: r['runner_id_faction']
            },
          }
        end
      else
        player = {
          player: {
            id: r['player_id'],
            active: r['player_active'],
            name_with_pronouns: "#{r['player_name']}#{r['player_pronouns'].present? ? " (#{r['player_pronouns']})" : ''}",
            corp_id: nil,
            runner_id: nil,
          },
          policy: {
            view_decks: view_player_decks
          },
          position: r['position'],
          points: r['points'],
          sos: r['sos'],
          extended_sos: r['extended_sos'],
          corp_points: r['corp_points'],
          runner_points: r['runner_points'],
          bye_points: r['bye_points'],
          manual_seed: r['player_manual_seed'],
          side_bias: r['side_bias']
        }
        player[:player][:corp_id] = {
          name: r['corp_id_name'],
          faction: r['corp_id_faction']
        }
        player[:player][:runner_id] = {
          name: r['runner_id_name'],
          faction: r['runner_id_faction']
        }
      end
      stage[:standings] << player
    end

    # stages = @tournament.stages
    # elimination = stages.select(&:double_elim?).first
    # elimination = stages.select(&:single_elim?).first if elimination.nil?

    stages_array = stages_map.keys.map { |stage_number|
      # stage = @tournament.stages.find_by(number: stage_number)

      {
        format: stages_map[stage_number][:format],
        rounds_complete: stages_map[stage_number][:num_rounds_completed],

        any_decks_viewable:,

        standings: stages_map[stage_number][:standings]
      }
    }

    # stages = @tournament.stages.includes(
    #   rounds: [pairings: %i[player1 player2]],
    #   registrations: [player: [:user, :corp_identity_ref, :runner_identity_ref, { registrations: [:stage] }]],
    #   standing_rows: [player: [:user, :corp_identity_ref, :runner_identity_ref, { registrations: [:stage] }]]
    # )
    # elimination = stages.select(&:double_elim?).first
    # elimination = stages.select(&:single_elim?).first if elimination.nil?
    render json: {
      is_player_meeting:,
      manual_seed: tournament_manual_seed,
      stages: stages_array,
      # is_player_meeting: stages.all? { |stage| stage.rounds.empty? },
      # manual_seed: @tournament.manual_seed?,
      # stages: stages.reverse.map do |stage|
      #   {
      #     format: stage.format,
      #     rounds_complete: stage.rounds.select(&:completed?).count,
      #     any_decks_viewable: stage.decks_visible_to(current_user) ||
      #       (elimination&.decks_visible_to(current_user) ? true : false),
      #     standings: render_standings_for_stage(stage)
      #   }
      # end
    }
  end

  def render_standings_for_stage(stage)
    if stage.elimination?
      # Compute standings on the fly during cut
      Rails.logger.info 'Computing cut standings'
      return compute_and_render_cut_standings stage
    end
    if stage.rounds.select(&:completed?).any?
      # Standings are stored explicitly at the end of a swiss round, so load those
      return render_completed_standings stage
    end

    # No standings during player meeting or first round, so list players
    render_player_list_for_player_meeting stage
  end

  def compute_and_render_cut_standings(stage)
    seed_by_player = stage.registrations.map { |r| [r.player_id, r.seed] }.to_h
    stage.standings.each_with_index.map do |standing, i|
      {
        player: standings_player(standing.player),
        policy: standings_policy(standing.player),
        position: i + 1,
        seed: seed_by_player[standing.player&.id]
      }
    end
  end

  def render_completed_standings(stage)
    stage.standing_rows.map do |row|
      {
        player: standings_player(row.player),
        policy: standings_policy(row.player),
        position: row.position,
        points: row.points,
        sos: row.sos,
        extended_sos: row.extended_sos,
        corp_points: row.corp_points || 0,
        runner_points: row.runner_points || 0,
        bye_points: row.bye_points || 0,
        manual_seed: row.manual_seed,
        side_bias: stage.format == 'single_sided_swiss' ? row.player.side_bias : nil
      }
    end
  end

  def render_player_list_for_player_meeting(stage)
    stage.players.sort.each_with_index.map do |player, i|
      {
        player: standings_player(player, show_ids: false),
        policy: standings_policy(player),
        position: i + 1,
        points: 0,
        sos: 0,
        extended_sos: 0,
        corp_points: 0,
        runner_points: 0,
        manual_seed: player.manual_seed,
        side_bias: nil
      }
    end
  end

  def standings_player(player, show_ids: true)
    return nil unless player

    {
      id: player.id,
      active: player.active,
      name_with_pronouns: player.name_with_pronouns,
      corp_id: show_ids ? standings_identity(player.corp_identity_object) : nil,
      runner_id: show_ids ? standings_identity(player.runner_identity_object) : nil
    }
  end

  def standings_policy(player)
    {
      view_decks: player&.decks_visible_to(current_user) ? true : false
    }
  end

  def standings_identity(identity)
    return nil unless identity

    {
      name: identity.name,
      faction: identity.faction
    }
  end

  def drop
    authorize @tournament, :update?

    @player.update(active: false)

    redirect_to tournament_players_path(@tournament)
  end

  def lock_registration
    authorize @tournament, :update?

    @player.update(registration_locked: true)
    @tournament.update(all_players_unlocked: false,
                       any_player_unlocked: @tournament.unlocked_players.count.positive?)

    redirect_to tournament_players_path(@tournament)
  end

  def unlock_registration
    authorize @tournament, :update?

    @player.update(registration_locked: false)
    @tournament.update(any_player_unlocked: true,
                       all_players_unlocked: @tournament.locked_players.count.zero?)

    redirect_to tournament_players_path(@tournament)
  end

  def reinstate
    authorize @tournament, :update?

    @player.update(active: true)

    redirect_to tournament_players_path(@tournament)
  end

  def meeting
    authorize @tournament, :show?
  end

  def registration
    authorize @tournament, :update?
    @edit_decks = params[:edit_decks]
    return unless @edit_decks

    begin
      @decks = Nrdb::Connection.new(current_user).decks
    rescue StandardError
      redirect_to login_path(return_to: request.fullpath)
    end
  end

  def view_decks
    authorize @player
  end

  private

  def player_params
    params.require(:player)
          .permit(:name, :pronouns, :corp_identity, :runner_identity, :corp_deck, :runner_deck,
                  :first_round_bye, :manual_seed, :include_in_stream, :fixed_table_number)
  end

  def organiser_view?
    params.require(:player)[:organiser_view] && @tournament.user_id == current_user.id
  end

  def set_player
    @player = Player.find(params[:id])
  end
end
