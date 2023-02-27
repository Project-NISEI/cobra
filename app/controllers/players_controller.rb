class PlayersController < ApplicationController
  before_action :set_tournament
  before_action :set_player, only: [:update, :destroy, :drop, :reinstate, :deck_registration]

  def index
    authorize @tournament, :update?

    @players = @tournament.players.active.sort_by { |p| p.name.downcase || '' }
    @dropped = @tournament.players.dropped.sort_by { |p| p.name.downcase || '' }
  end

  def create
    if @tournament.self_registration?
      authorize @tournament, :show?
    else
      authorize @tournament, :update?
    end

    player = @tournament.players.create(player_params)
    unless @tournament.current_stage.nil?
      @tournament.current_stage.players << player
    end

    if @tournament.nrdb_deck_registration?
      redirect_to deck_registration_tournament_player_path(@tournament, player)
    elsif player.user_id
      redirect_to tournament_path(@tournament)
    else
      redirect_to tournament_players_path(@tournament)
    end
  end

  def update
    authorize @tournament, :register?

    @player.update(player_params)

    if current_user.id == @tournament.user_id
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

  def deck_registration
    if @player.user_id == current_user.id
      authorize @tournament, :show?
    else
      authorize @tournament, :update?
    end
  end

  private

  def player_params
    params.require(:player)
      .permit(:name, :corp_identity, :runner_identity, :first_round_bye, :manual_seed, :user_id)
  end

  def set_player
    @player = Player.find(params[:id])
  end
end
