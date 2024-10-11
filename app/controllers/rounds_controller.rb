# frozen_string_literal: true

class RoundsController < ApplicationController
  before_action :set_tournament
  before_action :set_round, only: %i[edit update destroy repair complete update_timer]

  def index
    authorize @tournament, :show?
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

    stages = @tournament.stages.includes(:rounds)
    # .includes(
    #  rounds: [pairings: %i[player1 player2 stage]],
    #  registrations: [player: %i[user corp_identity_ref runner_identity_ref]]
    # )

    output = {
      policy: {
        update: @tournament.user == current_user
      },
      is_player_meeting: (@tournament.round_ids.size == 0),
      stages: []
    }

    stages.map do |stage|
      view_decks = stage.decks_visible_to(current_user) ? true : false
      stage_out = {
        name: stage.format.titleize,
        format: stage.format,
        rounds: []
      }
      stage.rounds.each do |r|
        # stage.rounds.pluck(%i[id number]).each do |id, num|
        round = {
          id: r.id,
          number: r.number,
          pairings: [],
          pairings_reported: 0
        }
        r.pairings.order(:table_number).pluck(%i[id table_number player1_id player2_id side intentional_draw
                                                 two_for_one score1 score1_corp score1_runner score2 score2_corp score2_runner]).each do |id, number, player1_id, player2_id, side, intentional_draw, two_for_one, score1, score1_corp, score1_runner, score2, score2_corp, score2_runner|
          round[:pairings_reported] += (score1.nil? and score2.nil?) ? 0 : 1
          player1 = players[player1_id]
          player2 = players[player2_id]
          round[:pairings] << {
            id:,
            table_number: number,
            table_label: stage.double_elim? ? "Game #{number}" : "Table #{number}",
            policy: {
              view_decks:
            },
            player1: {
              "name_with_pronouns": if player1.nil?
                                      '(Bye)'
                                    else
                                      !player1['pronouns'].empty? ? "#{player1['name']} (#{player1['pronouns']})" : player1['name']
                                    end,
              side: if side.nil?
                      nil
                    else
                      (side == 'player1_is_corp' ? 'corp' : 'runner')
                    end,
              side_label: if side.nil?
                            nil
                          else
                            "(#{(side == 'player1_is_corp' ? 'corp' : 'runner').to_s.titleize})"
                          end,
              "corp_id": if player1.nil?
                           nil
                         else
                           {
                             "name": player1['corp_identity'],
                             "faction": player1['corp_faction']
                           }
                         end,
              "runner_id": if player1.nil?
                             nil
                           else
                             {
                               "name": player1['runner_identity'],
                               "faction": player1['runner_faction']
                             }
                           end
            },
            player2: {
              "name_with_pronouns": if player2.nil?
                                      '(Bye)'
                                    else
                                      !player2['pronouns'].empty? ? "#{player2['name']} (#{player2['pronouns']})" : player2['name']
                                    end,
              side: if side.nil?
                      nil
                    else
                      (side == 'player1_is_corp' ? 'runner' : 'corp')
                    end,
              side_label: if side.nil?
                            nil
                          else
                            "(#{(side == 'player1_is_corp' ? 'runner' : 'corp').to_s.titleize})"
                          end,
              "corp_id": if player2.nil?
                           nil
                         else
                           {
                             "name": player2['corp_identity'],
                             "faction": player2['corp_faction']
                           }
                         end,
              "runner_id": if player2.nil?
                             nil
                           else
                             {
                               "name": player2['runner_identity'],
                               "faction": player2['runner_faction']
                             }
                           end
            },
            score_label: score_label(score1, score1_corp, score1_runner, score2, score2_corp,
                                     score2_runner),
            intentional_draw:,
            two_for_one:
          }
        end

        # def table_label
        #   stage.double_elim? ? "Game #{table_number}" : "Table #{table_number}"
        # end

        #  pairings: round.pairings.map do |pairing|
        #                         {
        #                           table_label: pairing.table_label,
        #                           player1: pairing_player1(stage, pairing),
        #                           player2: pairing_player2(stage, pairing),
        #                         }
        #                       end,
        #             pairings_reported: round.pairings.select { |p| p.score1 && p.score2 }.count
        stage_out[:rounds] << round
      end
      output[:stages] << stage_out
    end

    render json: output
    # {
    # stages: stages.map do |stage|
    # view_decks: stage.decks_visible_to(current_user) ? true : false
    # {
    #   name: stage.format.titleize,
    #   format: stage.format
    # rounds: stage.rounds.map do |round|
    #           {
    #             id: round.id,
    #             number: round.number,
    #             pairings: round.pairings.map do |pairing|
    #                         {
    #                           id: pairing.id,
    #                           table_number: pairing.table_number,
    #                           table_label: pairing.table_label,
    #                           policy: {
    #                             view_decks:
    #                           },
    #                           player1: pairing_player1(stage, pairing),
    #                           player2: pairing_player2(stage, pairing),
    #                           score_label: score_label(pairing),
    #                           intentional_draw: pairing.intentional_d raw,
    #                           two_for_one: pairing.two_for_one
    #                         }
    #                       end,
    #             pairings_reported: round.pairings.select { |p| p.score1 && p.score2 }.count
    #           }
    #         end
    # }
    #        end
    # }
  end

  def show
    authorize @tournament, :update?
    @round = Round.includes([:stage, { pairings: %i[stage tournament player1 player2] }]).find(params[:id])
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

  def pairing_player1(stage, pairing)
    pairing_player(stage, pairing.player1, pairing.player1_side)
  end

  def pairing_player2(stage, pairing)
    pairing_player(stage, pairing.player2, pairing.player2_side)
  end

  def pairing_player(stage, player, side)
    {
      name_with_pronouns: player.name_with_pronouns,
      side:,
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

  def score_label(score1, score1_corp, score1_runner, score2, score2_corp, score2_runner)
    return '-' if score1 == 0 && score2 == 0 # rubocop:disable Style/NumericPredicate

    ws = winning_side(score1_corp, score1_runner, score2_corp, score2_runner)

    return "#{score1} - #{score2}" unless ws

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
end
