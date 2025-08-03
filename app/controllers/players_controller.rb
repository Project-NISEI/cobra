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
