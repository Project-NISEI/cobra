class RoundsController < ApplicationController
  before_action :set_tournament
  before_action :set_round, only: [:show, :edit, :update, :destroy, :repair, :complete, :update_timer]

  def index
    authorize @tournament, :show?
    @stages = @tournament.stages.includes(
      :tournament, rounds: [:tournament, :stage, pairings: [:tournament, :stage, :round]])
    @players = @tournament.players
                          .includes(:corp_identity_ref, :runner_identity_ref)
                          .index_by(&:id).merge({ nil => NilPlayer.new })
  end

  def new_view
    authorize @tournament, :show?
  end

  def pairings_data
    authorize @tournament, :show?
    render json: {
      details: @tournament,
      policy: {
        update: @tournament.user == current_user
      },
      stages: @tournament.stages.includes(rounds: [pairings: [:player1, :player2]]).map { |stage| {
        details: stage,
        name: stage.format.titleize,
        policy: {
          view_decks: stage.decks_visible_to(current_user) ? true : false
        },
        rounds: stage.rounds.map { |round| {
          details: round,
          pairings: round.pairings.map { |pairing| {
            details: pairing,
            player1: pairing.player1,
            player2: pairing.player2
          } },
          pairings_reported: round.pairings.reported.count,
        } }
      } }
    }
  end

  def show
    authorize @tournament, :update?
    @players = @tournament.players
                          .includes(:corp_identity_ref, :runner_identity_ref)
                          .index_by(&:id).merge({ nil => NilPlayer.new })
  end

  def create
    authorize @tournament, :update?

    @tournament.pair_new_round!

    redirect_to tournament_rounds_path(@tournament)
  end

  def edit
    authorize @tournament, :update?
  end

  def update
    authorize @tournament, :update?

    @round.update(round_params)

    redirect_to tournament_round_path(@tournament, @round)
  end

  def destroy
    authorize @tournament, :update?

    @round.destroy!

    redirect_to tournament_rounds_path(@tournament)
  end

  def repair
    authorize @tournament, :update?

    @round.repair!

    redirect_to tournament_round_path(@tournament, @round)
  end

  def complete
    authorize @tournament, :update?

    @round.update!(completed: params[:completed])
    @round.timer.stop!

    redirect_to tournament_rounds_path(@tournament)
  end

  def update_timer
    authorize @tournament, :update?

    @round.update!(length_minutes: params[:length_minutes])

    operation = params[:operation]
    if operation == "start"
      @round.timer.start!
    elsif operation == "stop"
      @round.timer.stop!
    elsif operation == "reset"
      @round.timer.reset!
    end

    redirect_to tournament_rounds_path(@tournament)
  end

  private

  def set_round
    @round = Round.find(params[:id])
  end

  def round_params
    params.require(:round).permit(:weight)
  end
end
