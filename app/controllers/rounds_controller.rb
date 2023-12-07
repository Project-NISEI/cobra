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
      tournament_id: @tournament.id,
      policy: {
        update: @tournament.user == current_user
      },
      stages: @tournament.stages.includes(
        rounds: [pairings: [:player1, :player2]],
        registrations: [player: [:user, :corp_identity_ref, :runner_identity_ref]]
      ).map { |stage|
        view_decks = stage.decks_visible_to(current_user) ? true : false
        {
          name: stage.format.titleize,
          rounds: stage.rounds.map { |round| {
            id: round.id,
            number: round.number,
            pairings: round.pairings.map { |pairing| {
              id: pairing.id,
              round_id: pairing.round_id,
              table_number: pairing.table_number,
              policy: {
                view_decks: view_decks
              },
              player1: pairing_player1(stage, pairing),
              player2: pairing_player2(stage, pairing),
              score_label: score_label(pairing),
              intentional_draw: pairing.intentional_draw,
              two_for_one: pairing.two_for_one
            } },
            pairings_reported: round.pairings.reported.count,
          } }
        }
      }
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

  def pairing_player1(stage, pairing)
    pairing_player(stage, pairing.player1, pairing.player1_side)
  end

  def pairing_player2(stage, pairing)
    pairing_player(stage, pairing.player2, pairing.player2_side)
  end

  def pairing_player(stage, player, side)
    {
      name_with_pronouns: player.name_with_pronouns,
      side_label: side_label(stage, side),
      corp_id: pairing_identity(player.corp_identity_object),
      runner_id: pairing_identity(player.runner_identity_object)
    }
  end

  def side_label(stage, side)
    return nil unless stage.single_sided? && side

    "(#{side.to_s.titleize})"
  end

  def pairing_identity(identity)
    return nil unless identity
    {
      name: identity.name,
      faction: identity.faction
    }
  end

  def score_label(pairing)
    return "-" if pairing.score1 == 0 && pairing.score2 == 0
    ws = winning_side(pairing)

    return "#{pairing.score1} - #{pairing.score2}" unless ws

    "#{pairing.score1} - #{pairing.score2} (#{ws})"
  end

  def winning_side(pairing)
    corp_score = (pairing.score1_corp || 0) + (pairing.score2_corp || 0)
    runner_score = (pairing.score1_runner || 0) + (pairing.score2_runner || 0)

    case
    when corp_score - runner_score == 0
      nil
    when corp_score - runner_score < 0
      'R'
    else
      'C'
    end
  end
end
