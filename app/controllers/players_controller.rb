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
    render json: @tournament.players.active
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

    if @player.registration_locked?
      update = params.require(:player).permit(:include_in_stream)
    else
      update = player_params
    end
    if is_organiser_view
      redirect_to tournament_players_path(@tournament)
    else
      redirect_to tournament_path(@tournament)
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
