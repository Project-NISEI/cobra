class PlayersController < ApplicationController
  before_action :set_tournament
  before_action :set_player, only: [:update, :destroy, :drop, :reinstate, :lock_decks, :unlock_decks, :registration]

  def index
    authorize @tournament, :update?

    @players = @tournament.players.active.sort_by { |p| p.name.downcase || '' }
    @dropped = @tournament.players.dropped.sort_by { |p| p.name.downcase || '' }
  end

  def create
    authorize Player
    if @tournament.self_registration?
      authorize @tournament, :show?
    else
      authorize @tournament, :update?
    end

    params = player_params
    unless is_organiser_view
      params[:user_id] = current_user.id
    end

    player = @tournament.players.create(params)
    unless @tournament.current_stage.nil?
      @tournament.current_stage.players << player
    end

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

    params=player_params
    unless is_organiser_view
      params[:user_id] = current_user.id
      if @tournament.nrdb_deck_registration?
        if @player.decks_locked?
          params = params.except(:corp_identity, :runner_identity,
                                 :corp_deck, :runner_deck,
                                 :corp_deck_format, :runner_deck_format)
        else
          params[:decks_locked] = true
          params[:corp_deck] = JSON.parse(params[:corp_deck])
          params[:runner_deck] = JSON.parse(params[:runner_deck])
        end
      else
        params = params.except(:corp_deck, :runner_deck, :corp_deck_format, :runner_deck_format)
      end
    end

    @player.update(params)

    if current_user.id == @tournament.user_id && @player.user_id != current_user.id
      redirect_to tournament_players_path(@tournament)
    else
      redirect_to tournament_path(@tournament)
    end
  end

  def destroy
    authorize @tournament, :update?

    @player.destroy

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

  def lock_decks
    authorize @tournament, :update?

    @player.update(decks_locked: true)

    redirect_to tournament_players_path(@tournament)
  end

  def unlock_decks
    authorize @tournament, :update?

    @player.update(decks_locked: false)

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
  end

  private

  def player_params
    params.require(:player)
      .permit(:name, :corp_identity, :runner_identity,
              :corp_deck, :runner_deck, :corp_deck_format, :runner_deck_format,
              :first_round_bye, :manual_seed)
  end

  def is_organiser_view
    params.require(:player)[:organiser_view] && @tournament.user_id == current_user.id
  end

  def set_player
    @player = Player.find(params[:id])
  end
end
