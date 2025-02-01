# frozen_string_literal: true

class NrtmJson
  attr_reader :tournament

  def initialize(tournament)
    @tournament = tournament
  end

  def data(tournament_url)
    # rubocop:disable Naming/VariableName
    # preliminaryRounds must be named in camelCase to match the expected NRTM format.
    preliminaryRounds = 0
    players = []
    if swiss_stage
      preliminaryRounds = swiss_stage.rounds.count
      players = swiss_stage.standings.each_with_index.map do |standing, i|
        {
          id: standing.player.id,
          name: standing.name,
          rank: i + 1,
          corpIdentity: (standing.corp_identity.name.gsub(/[“”]/, '"') if standing.corp_identity.id),
          runnerIdentity: (standing.runner_identity.name.gsub(/[“”]/, '"') if standing.runner_identity.id),
          matchPoints: standing.points,
          strengthOfSchedule: standing.sos,
          extendedStrengthOfSchedule: standing.extended_sos
        }
      end
    end

    {
      name: tournament.name,
      date: tournament.date.to_fs(:db),
      cutToTop: cut_stage.players.count,
      preliminaryRounds:,
      tournamentOrganiser: {
        nrdbId: tournament.user.nrdb_id,
        nrdbUsername: tournament.user.nrdb_username
      },
      players:,
      eliminationPlayers: cut_stage.standings.each_with_index.map do |standing, i|
        {
          id: standing.player&.id,
          name: standing.player&.name,
          rank: i + 1,
          seed: standing.player&.seed_in_stage(cut_stage)
        }
      end,
      rounds: swiss_pairing_data + cut_pairing_data,
      uploadedFrom: 'Cobra',
      links: [
        { rel: 'schemaderivedfrom', href: 'http://steffens.org/nrtm/nrtm-schema.json' },
        { rel: 'uploadedfrom', href: tournament_url }
      ]
    }
    # rubocop:enable Naming/VariableName
  end

  private

  def swiss_stage
    @swiss_stage ||= tournament.stages.find_by(format: %i[swiss single_sided_swiss])
  end

  def swiss_pairing_data
    return [] unless swiss_stage

    swiss_stage.rounds.map do |round|
      round.pairings.map do |pairing|
        swiss_stage.single_sided? ? single_sided_pairing_data(pairing) : double_sided_pairing_data(pairing)
      end
    end
  end

  def cut_stage
    tournament.stages.find_by(format: :single_elim) || tournament.stages.find_by(format: :double_elim) || NilStage.new
  end

  def cut_pairing_data
    return [] unless cut_stage

    cut_stage.rounds.map do |round|
      round.pairings.map do |pairing|
        single_sided_pairing_data(pairing)
      end
    end
  end

  def double_sided_pairing_data(pairing)
    {
      table: pairing.table_number,
      player1: {
        id: pairing.player1_id,
        runnerScore: pairing.score1_runner,
        corpScore: pairing.score1_corp,
        combinedScore: pairing.score1
      },
      player2: {
        id: pairing.player2_id,
        runnerScore: pairing.score2_runner,
        corpScore: pairing.score2_corp,
        combinedScore: pairing.score2
      },
      intentionalDraw: pairing.intentional_draw.present?,
      twoForOne: pairing.two_for_one.present?,
      eliminationGame: false
    }
  end

  def single_sided_pairing_data(pairing)
    {
      table: pairing.table_number,
      player1: {
        id: pairing.player1.id,
        role: pairing.player1_side&.to_s
      }.merge(score_for_pairing(pairing, pairing.player1_side, pairing.score1, pairing.score2)),
      player2: {
        id: pairing.player2.id,
        role: pairing.player2_side&.to_s
      }.merge(score_for_pairing(pairing, pairing.player2_side, pairing.score2, pairing.score1)),
      intentionalDraw: pairing.intentional_draw.present?,
      twoForOne: pairing.two_for_one.present?,
      eliminationGame: pairing.stage.single_elim? || pairing.stage.double_elim?
    }
  end

  def score_for_pairing(pairing, side, score, opp_score)
    if pairing.stage.single_elim? || pairing.stage.double_elim?
      return { winner: (score > opp_score if score && opp_score) }
    end

    hash = { combinedScore: score }
    hash.merge!({ runnerScore: nil, corpScore: score }) if side == :corp
    hash.merge!({ runnerScore: score, corpScore: nil }) if side == :runner
    hash.merge!({ runnerScore: nil, corpScore: nil }) if side.nil?
    hash
  end
end
