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
    unless is_organiser_view
      params[:user_id] = current_user.id
    end

    player = @tournament.players.create(params.except(:corp_deck, :runner_deck))
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
    end

    @player.update(params.except(:corp_deck, :runner_deck))

    if @tournament.nrdb_deck_registration?
      save_deck(params, :corp_deck, 'corp')
      save_deck(params, :runner_deck, 'runner')
    end

    if current_user.id == @tournament.user_id && @player.user_id != current_user.id
      redirect_to tournament_players_path(@tournament)
    else
      redirect_to tournament_path(@tournament)
    end
  end

  def save_deck(params, param, side)
    return unless params.has_key?(param)
    request = JSON.parse(params[param])
    @player.decks.destroy_by(side: side)
    details = request['details']
    details.keep_if { |key| Deck.column_names.include? key }
    details['side'] = side
    deck = @player.decks.create(details)
    deck.cards.create(request['cards'])
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
              :first_round_bye, :manual_seed)
  end

  def is_organiser_view
    params.require(:player)[:organiser_view] && @tournament.user_id == current_user.id
  end

  def set_player
    @player = Player.find(params[:id])
  end
end
