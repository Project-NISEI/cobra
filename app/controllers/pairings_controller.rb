class PairingsController < ApplicationController
  before_action :set_tournament
  attr_reader :tournament

  def index
    authorize @tournament, :show?

    @pairings = round.pairings.inject([]) do |pairings, p|
      pairings << {
        table_number: p.table_number,
        player1_name: p.player1.name_with_pronouns,
        player2_name: p.player2.name_with_pronouns,
        pairing: p
      }
      pairings << {
        table_number: p.table_number,
        player1_name: p.player2.name_with_pronouns,
        player2_name: p.player1.name_with_pronouns,
        pairing: p
      }
    end.sort_by do |p|
      # Sort by username for doublesided, but Corp username for Single-Sided Swiss.
      if p[:pairing].round.stage.format == :single_sided_swiss.to_s
        if p[:pairing].side == 'player1_is_corp'
          p[:player1_name].downcase
        else
          p[:player2_name].downcase
        end
      else
        p[:player1_name].downcase
      end
    end
  end

  def create
    authorize @tournament, :update?

    round.pairings.create(pairing_params)

    redirect_to tournament_round_path(tournament, round)
  end

  def report
    authorize @tournament, :update?

    pairing.update(score_params)

    redirect_back(fallback_location: tournament_rounds_path(tournament))
  end

  def destroy
    authorize @tournament, :update?

    pairing.destroy

    redirect_to tournament_round_path(tournament, round)
  end

  def match_slips
    authorize @tournament, :edit?

    if params[:collate]
      @pairings = round.collated_pairings
    else
      @pairings = round.pairings
    end
  end

  def view_decks
    authorize @tournament, :show?
    authorize pairing
  end

  private

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
          .permit(:score1_runner, :score1_corp, :score2_runner, :score2_corp, :score1, :score2, :side, :intentional_draw, :two_for_one)
  end
end
