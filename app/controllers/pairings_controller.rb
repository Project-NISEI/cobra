# frozen_string_literal: true

class PairingsController < ApplicationController
  before_action :set_tournament
  attr_reader :tournament

  def index
    authorize @tournament, :show?

    @pairings = round.pairings.includes(:player1, :player2).inject([]) do |pairings, p|
      pairings << {
        table_number: p.table_number,
        player1_name: p.player1.name_with_pronouns,
        player1_side: p.side == 'player1_is_corp' ? ' (Corp)' : ' (Runner)',
        player2_name: p.player2.name_with_pronouns,
        player2_side: p.side == 'player1_is_corp' ? ' (Runner)' : ' (Corp)',
        pairing: p
      }
      pairings << {
        table_number: p.table_number,
        player1_name: p.player2.name_with_pronouns,
        player1_side: p.side == 'player1_is_corp' ? ' (Runner)' : ' (Corp)',
        player2_name: p.player1.name_with_pronouns,
        player2_side: p.side == 'player1_is_corp' ? ' (Corp)' : ' (Runner)',
        pairing: p
      }
    end
    @pairings = @pairings.sort_by do |p|
      p[:player1_name].downcase
    end
  end

  def create
    authorize @tournament, :update?

    round.pairings.create(pairing_params)

    redirect_to tournament_round_path(tournament, round)
  end

  def report
    authorize @tournament, :update?

    save_report

    redirect_back(fallback_location: tournament_rounds_path(tournament))
  end

  def reset_self_report
    authorize @tournament, :update?

    SelfReport.where(pairing_id: pairing.id).destroy_all

    redirect_back(fallback_location: tournament_rounds_path(tournament))
  end

  def self_report
    authorize @tournament, :self_report?
    authorize pairing, :can_self_report?

    self_report_score = self_report_score_params.merge(pairing_id: pairing.id).merge(report_player_id: current_user.id)
    SelfReport.create(self_report_score)

    # if both players have reported and the reported scores match, finalize scores for the pairing
    reports = Pairing.find(params[:id]).self_reports

    if reports.size == 2

      # if reports don't match, do nothing (later replaced by notification)
      if reports[0].score1 != reports[1].score1 ||
         reports[0].score2 != reports[1].score2 ||
         reports[0].score1_corp != reports[1].score1_corp ||
         reports[0].score2_corp != reports[1].score2_corp ||
         reports[0].score1_runner != reports[1].score1_runner ||
         reports[0].score2_runner != reports[1].score2_runner

        return render json: { success: true }, status: :ok
      end

      save_report

    end
    render json: { success: true }, status: :ok
  end

  def destroy
    authorize @tournament, :update?

    pairing.destroy

    redirect_to tournament_round_path(tournament, round)
  end

  def match_slips
    authorize @tournament, :edit?

    @pairings = if params[:collate]
                  round.collated_pairings
                else
                  round.pairings
                end
  end

  def view_decks
    authorize @tournament, :show?
    authorize pairing
  end

  def pairing_presets
    authorize @tournament, :show?
    render json: { presets: helpers.presets(pairing), csrf_token: form_authenticity_token }
  end

  private

  def save_report
    pairing.update(score_params)

    return unless score_params.key?('side') && pairing.reported?

    score1_corp = pairing.score1_corp
    pairing.score1_corp = pairing.score1_runner
    pairing.score1_runner = score1_corp

    score2_corp = pairing.score2_corp
    pairing.score2_corp = pairing.score2_runner
    pairing.score2_runner = score2_corp

    pairing.save
  end

  def round
    @round ||= Round.find(params[:round_id])
  end

  def pairing
    @pairing ||= Pairing.find(params[:id])
  end

  def pairing_params
    params.require(:pairing).permit(:player1_id, :player2_id, :table_number, :side)
  end

  def score_params
    params.require(:pairing)
          .permit(:score1_runner, :score1_corp, :score2_runner, :score2_corp,
                  :score1, :score2, :side, :intentional_draw, :two_for_one)
  end

  def self_report_score_params
    params.require(:pairing)
          .permit(:score1_runner, :score1_corp, :score2_runner, :score2_corp,
                  :score1, :score2, :side, :intentional_draw, :two_for_one)
  end
end
