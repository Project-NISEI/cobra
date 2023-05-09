class PlayersController < ApplicationController
  before_action :set_tournament
  before_action :set_player, only: [:update, :destroy, :drop, :reinstate, :registration]

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
    if @tournament.user_id != current_user.id
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
    if @tournament.user_id != current_user.id
      params[:user_id] = current_user.id
    end
    validate_deck_registration(params)

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
      .permit(:name, :corp_identity, :runner_identity, :corp_deck, :runner_deck,
              :first_round_bye, :manual_seed, :user_id)
  end

  def set_player
    @player = Player.find(params[:id])
  end

  def validate_deck_registration(params)
    if params[:corp_deck]
      corp_deck = JSON.parse(params[:corp_deck])
      corp_id = Identity.where(nrdb_code: corp_deck['cards'].keys).first
      params[:corp_identity] = corp_id&.name
    end
    if params[:runner_deck]
      runner_deck = JSON.parse(params[:runner_deck])
      runner_id = Identity.where(nrdb_code: runner_deck['cards'].keys).first
      params[:runner_identity] = runner_id&.name
    end
  end
end
