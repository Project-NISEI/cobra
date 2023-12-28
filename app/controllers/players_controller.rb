class PlayersController < ApplicationController
  before_action :set_tournament
  before_action :set_player, only: [:update, :destroy, :drop, :reinstate,
                                    :lock_registration, :unlock_registration, :registration, :view_decks]

  def index
    authorize @tournament, :update?

    @players = @tournament.players.active.sort_by { |p| p.name.downcase || '' }
    @dropped = @tournament.players.dropped.sort_by { |p| p.name.downcase || '' }
  end

  def download_decks
    authorize @tournament, :update?
    render json: @tournament.players
                            .sort_by { |p| p.name }
                            .flat_map { |p| p.decks.sort_by { |d| d.side_id } }
                            .map { |d| d.as_view(current_user) }
  end

  def download_streaming
    authorize @tournament, :update?
    render json: @tournament.players.active
                            .sort_by { |p| p.name }
                            .map { |p| {
                              name: p.name_with_pronouns,
                              include_in_stream: p.include_in_stream?
                            } }
  end

  def create
    authorize Player
    if @tournament.registration_open?
      authorize @tournament, :show?
    else
      authorize @tournament, :update?
    end

    params = player_params
    unless is_organiser_view
      params[:user_id] = current_user.id
    end

    player = @tournament.players.create(params.except(:corp_deck, :runner_deck))
    unless @tournament.current_stage.nil?
      @tournament.current_stage.players << player
    end
    @tournament.update(any_player_unlocked: true,
                       all_players_unlocked: @tournament.locked_players.count == 0)

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

    if is_organiser_view
      if params.require(:player)[:registration_view]
        redirect_to registration_tournament_player_path(@tournament, @player)
      else
        redirect_to tournament_players_path(@tournament)
      end
      update = player_params
    else
      redirect_to tournament_path(@tournament)
      if @player.registration_locked?
        update = params.require(:player).permit(:include_in_stream)
      else
        update = player_params
      end
      update[:user_id] = current_user.id
    end

    @player.update(update.except(:corp_deck, :runner_deck))
    if @tournament.nrdb_deck_registration?
      save_deck(update, :corp_deck, 'corp')
      save_deck(update, :runner_deck, 'runner')
    end
  end

  def save_deck(params, param, side)
    return unless params.has_key?(param)
    begin
      request = JSON.parse(params[param])
    rescue
      @player.decks.destroy_by(side_id: side)
      return
    end
    details = request['details']
    if details['user_id'] && details['user_id'] != current_user.id
      return
    end
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
    @tournament.update(any_player_unlocked: @tournament.unlocked_players.count > 0,
                       all_players_unlocked: @tournament.locked_players.count == 0)

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
      rounds: [pairings: [:player1, :player2]],
      registrations: [player: [:user, :corp_identity_ref, :runner_identity_ref, registrations: [:stage]]],
      standing_rows: [player: [:user, :corp_identity_ref, :runner_identity_ref, registrations: [:stage]]]
    )
    double_elim = stages.select { |stage| stage.double_elim? }.first
    render json: {
      tournament_id: @tournament.id,
      is_player_meeting: stages.all? { |stage| stage.rounds.empty? },
      stages: stages.reverse.map { |stage|
        {
          format: stage.format,
          manual_seed: @tournament.manual_seed?,
          rounds_complete: stage.rounds.select { |round| round.completed? }.count,
          any_decks_viewable: stage.decks_visible_to(current_user) || double_elim&.decks_visible_to(current_user) ? true : false,
          standings: standing_rows(stage),
        }
      }
    }
  end

  def standing_rows(stage)
    seed_by_player = stage.registrations.map { |r| [r.player_id, r.seed] }.to_h
    if stage.double_elim?
      stage.standings.each_with_index.map { |standing, i| {
        player: standings_player(standing.player),
        policy: standings_policy(standing.player),
        position: i + 1,
        seed: seed_by_player[standing.player.id]
      } }
    else
      if stage.rounds.select { |round| round.completed? }.any?
        stage.standing_rows.map { |row| {
          player: standings_player(row.player),
          policy: standings_policy(row.player),
          position: row.position,
          points: row.points,
          sos: row.sos,
          extended_sos: row.extended_sos,
          corp_points: row.corp_points || 0,
          runner_points: row.runner_points || 0,
          manual_seed: row.manual_seed,
        } }
      else
        stage.players.sort.each_with_index.map { |player, i| {
          player: standings_player(player),
          policy: standings_policy(player),
          position: i + 1,
          points: 0,
          sos: 0,
          extended_sos: 0,
          corp_points: 0,
          runner_points: 0,
          manual_seed: player.manual_seed,
        } }
      end
    end
  end

  def standings_player(player)
    {
      id: player.id,
      name_with_pronouns: player.name_with_pronouns,
      corp_id: standings_identity(player.corp_identity_object),
      runner_id: standings_identity(player.runner_identity_object)
    }
  end

  def standings_policy(player)
    {
      view_decks: player.decks_visible_to(current_user) ? true : false
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
                       any_player_unlocked: @tournament.unlocked_players.count > 0)

    redirect_to tournament_players_path(@tournament)
  end

  def unlock_registration
    authorize @tournament, :update?

    @player.update(registration_locked: false)
    @tournament.update(any_player_unlocked: true,
                       all_players_unlocked: @tournament.locked_players.count == 0)

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
    if @edit_decks
      begin
        @decks = Nrdb::Connection.new(current_user).decks
      rescue
        redirect_to login_path(:return_to => request.fullpath)
      end
    end
  end

  def view_decks
    authorize @player
  end

  private

  def player_params
    params.require(:player)
          .permit(:name, :pronouns, :corp_identity, :runner_identity, :corp_deck, :runner_deck,
                  :first_round_bye, :manual_seed, :include_in_stream)
  end

  def is_organiser_view
    params.require(:player)[:organiser_view] && @tournament.user_id == current_user.id
  end

  def set_player
    @player = Player.find(params[:id])
  end
end
