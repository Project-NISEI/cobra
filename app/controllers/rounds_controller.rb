# frozen_string_literal: true

class RoundsController < ApplicationController
  before_action :set_tournament
  before_action :set_round, only: %i[edit update destroy repair complete update_timer]

  def index
    authorize @tournament, :update?
    @stages = @tournament.stages.includes(
      :tournament, rounds: [:tournament, :stage, { pairings: %i[tournament stage round] }]
    )
    @players = @tournament.players
                          .includes(:corp_identity_ref, :runner_identity_ref)
                          .index_by(&:id).merge({ nil => NilPlayer.new })
  end

  def view_pairings
    authorize @tournament, :show?
  end

  def pairings_data
    authorize @tournament, :show?

    render json: {
      policy: {
        update: @tournament.user == current_user
      },
      is_player_meeting: @tournament.round_ids.empty?,
      stages: pairings_data_stages
    }
  end

  def show
    authorize @tournament, :update?
    @round = Round.includes([:stage, { pairings: %i[stage tournament player1 player2 self_reports] }]).find(params[:id])
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
    case operation
    when 'start'
      @round.timer.start!
    when 'stop'
      @round.timer.stop!
    when 'reset'
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

  def pairings_data_stages
    players = pairings_data_players
    @tournament.stages.includes(:rounds).map do |stage|
      {
        name: stage.format.titleize,
        format: stage.format,
        rounds: pairings_data_rounds(stage, players)
      }
    end
  end

  def pairings_data_players
    players_results = Player.connection.exec_query("
      SELECT
        p.id,
        p.user_id,
        p.name,
        p.pronouns,
        p.corp_identity,
        ci.faction as corp_faction,
        p.runner_identity,
        ri.faction AS runner_faction
      FROM
        players p
        LEFT JOIN identities AS ci ON p.corp_identity_ref_id = ci.id
        LEFT JOIN identities AS ri ON p.runner_identity_ref_id = ri.id
      WHERE p.tournament_id = #{@tournament.id}")

    players = {}
    players_results.to_a.each do |p|
      players[p['id']] = p
    end
    players
  end

  def pairings_data_rounds(stage, players)
    view_decks = stage.decks_visible_to(current_user) ? true : false
    stage.rounds.map do |round|
      pairings_data_round(stage, players, view_decks, round)
    end
  end

  def pairings_data_round(stage, players, view_decks, round)
    pairings = []
    pairings_reported = 0
    pairings_fields = %i[id table_number player1_id player2_id side intentional_draw
                         two_for_one score1 score1_corp score1_runner score2 score2_corp score2_runner]
    round.pairings.order(:table_number).pluck(pairings_fields).each do | # rubocop:disable Metrics/ParameterLists
    id, table_number, player1_id, player2_id, side, intentional_draw,
      two_for_one, score1, score1_corp, score1_runner, score2, score2_corp, score2_runner|
      pairings_reported += score1.nil? && score2.nil? ? 0 : 1
      # Only show own self report
      self_report = SelfReport.where(pairing_id: id, report_player_id: current_user.id).first if current_user
      if self_report
        self_report_score_label = score_label(@tournament.swiss_format, player1_side(side),
                                              self_report.score1, self_report.score1_corp,
                                              self_report.score1_runner,
                                              self_report.score2,
                                              self_report.score2_corp,
                                              self_report.score2_runner)
      end
      pairings << {
        id:,
        table_number:,
        table_label: stage.double_elim? || stage.single_elim? ? "Game #{table_number}" : "Table #{table_number}",
        policy: {
          view_decks:,
          self_report: SelfReporting.self_report_allowed(current_user,
                                                         self_report,
                                                         players[player1_id]&.dig('user_id'),
                                                         players[player2_id]&.dig('user_id')) &&
                       score1.nil? && score2.nil?
        },
        player1: pairings_data_player(players[player1_id], player1_side(side)),
        player2: pairings_data_player(players[player2_id], player2_side(side)),
        score_label: score_label(@tournament.swiss_format, player1_side(side),
                                 score1, score1_corp, score1_runner,
                                 score2, score2_corp, score2_runner),
        intentional_draw:,
        two_for_one:,
        self_report: ({ report_player_id: self_report.report_player_id, label: self_report_score_label } if self_report)
      }
    end
    {
      id: round.id,
      number: round.number,
      pairings:,
      pairings_reported:
    }
  end

  def pairings_data_player(player, side)
    {
      name_with_pronouns: name_with_pronouns(player),
      side:,
      user_id: (player['user_id'] if player),
      side_label: side_label(side),
      corp_id: id(player, 'corp'),
      runner_id: id(player, 'runner')
    }
  end

  def score_label(swiss_format, player1_side, score1, score1_corp, score1_runner, score2, score2_corp, score2_runner) # rubocop:disable Metrics/ParameterLists
    # No scores reported.
    return '-' if score1 == 0 && score2 == 0 # rubocop:disable Style/NumericPredicate

    ws = winning_side(score1_corp, score1_runner, score2_corp, score2_runner)

    # No winning side means double-sided swiss.
    return "#{score1} - #{score2}" unless ws

    if swiss_format == 'single_sided'
      # Player 1 is on the right when corp.
      return "#{score1} - #{score2} (#{ws})" if player1_side == 'corp'

      return "#{score2} - #{score1} (#{ws})"

    end

    "#{score1} - #{score2} (#{ws})"
  end

  def winning_side(score1_corp, score1_runner, score2_corp, score2_runner)
    corp_score = (score1_corp || 0) + (score2_corp || 0)
    runner_score = (score1_runner || 0) + (score2_runner || 0)

    if (corp_score - runner_score).zero?
      nil
    elsif (corp_score - runner_score).negative?
      'R'
    else
      'C'
    end
  end

  def name_with_pronouns(player)
    if player.nil?
      '(Bye)'
    elsif !player['pronouns']&.empty?
      "#{player['name']} (#{player['pronouns']})"
    else
      player['name']
    end
  end

  def id(player, side)
    if player.nil?
      nil
    else
      {
        "name": player["#{side}_identity"],
        "faction": player["#{side}_faction"]
      }
    end
  end

  def player1_side(pairing_side)
    if pairing_side.nil?
      nil
    else
      (pairing_side == 'player1_is_corp' ? 'corp' : 'runner')
    end
  end

  def player2_side(pairing_side)
    if pairing_side.nil?
      nil
    else
      (pairing_side == 'player1_is_corp' ? 'runner' : 'corp')
    end
  end

  def side_label(side)
    if side.nil?
      nil
    else
      "(#{side.to_s.titleize})"
    end
  end
end
