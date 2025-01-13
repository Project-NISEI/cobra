# frozen_string_literal: true

module PairingsHelper
  def pairing_player_select(form, label, round)
    form.input label,
               collection: round.unpaired_players,
               include_blank: '(Bye)',
               label: false,
               wrapper: false,
               input_html: { class: 'form-control mx-2' }
  end

  def pairing_player1_side_select(form, label)
    form.input label,
               collection: { 'Corp' => 'player1_is_corp', 'Runner' => 'player1_is_runner' },
               include_blank: 'Player 1 Side',
               label: false,
               wrapper: false,
               input_html: { class: 'form-control mx-2' }
  end

  def preset_score_button(pairing, data)
    link_to data[:label],
            report_tournament_round_pairing_path(
              pairing.tournament,
              pairing.round,
              pairing,
              pairing: data
            ),
            method: :post,
            class: 'btn btn-primary'
  end

  def side_value(player, side, pairing)
    return unless player_is_in_pairing(player, pairing)

    %i[player1_is_corp player1_is_runner].tap do |options|
      options.reverse! if (side == :runner) ^ (pairing.player2_id == player.id)
    end.first
  end

  def set_side_button(player, side, pairing)
    return unless player_is_in_pairing(player, pairing)

    value = side_value(player, side, pairing)
    active = (pairing.side.try(:to_sym) == value)

    link_to side.capitalize,
            report_tournament_round_pairing_path(
              pairing.tournament,
              pairing.round_id,
              pairing,
              pairing: { side: value }
            ),
            method: :post,
            class: "btn btn-sm mr-1 #{active ? 'btn-dark' : 'btn-outline-dark'}"
  end

  def presets(pairing)
    # Double-sided round
    unless pairing.stage.single_sided?
      return [
        { score1_corp: 3, score2_runner: 0, score1_runner: 3, score2_corp: 0, label: '6-0' },
        { score1_corp: 3, score2_runner: 0, score1_runner: 0, score2_corp: 3, label: '3-3 (C)' },
        { score1_corp: 0, score2_runner: 3, score1_runner: 3, score2_corp: 0, label: '3-3 (R)' },
        { score1_corp: 0, score2_runner: 3, score1_runner: 0, score2_corp: 3, label: '0-6' }
      ]
    end

    # Single-sided swiss round
    if pairing.stage.single_sided_swiss?
      if pairing.player1_is_corp?
        return [
          { score1_corp: 3, score2_corp: 0, score1_runner: 0, score2_runner: 0, intentional_draw: false,
            label: 'Corp Win' },
          { score1_corp: 1, score2_corp: 0, score1_runner: 0, score2_runner: 1, intentional_draw: false, label: 'Tie' },
          { score1_corp: 1, score2_corp: 0, score1_runner: 0, score2_runner: 1, intentional_draw: true,
            label: 'Intentional Draw' },
          { score1_corp: 0, score2_corp: 0, score1_runner: 0, score2_runner: 3, intentional_draw: false,
            label: 'Runner Win' }
        ]
      else
        return [
          { score1_corp: 0, score2_corp: 3, score1_runner: 0, score2_runner: 0, intentional_draw: false,
            label: 'Corp Win' },
          { score1_corp: 0, score2_corp: 1, score1_runner: 1, score2_runner: 0, intentional_draw: false, label: 'Tie' },
          { score1_corp: 0, score2_corp: 1, score1_runner: 1, score2_runner: 0, intentional_draw: true,
            label: 'Intentional Draw' },
          { score1_corp: 0, score2_corp: 0, score1_runner: 3, score2_runner: 0, intentional_draw: false,
            label: 'Runner Win' }
        ]
      end
    end

    # Single-sided elimination round
    if pairing.player1_is_corp?
      return [
        { score1_corp: 3, score2_runner: 0, score1_runner: 0, score2_corp: 0, label: '3-0' },
        { score1_corp: 0, score2_runner: 3, score1_runner: 0, score2_corp: 0, label: '0-3' }
      ]
    end

    if pairing.player1_is_runner?
      return [
        { score1_corp: 0, score2_runner: 0, score1_runner: 3, score2_corp: 0, label: '3-0' },
        { score1_corp: 0, score2_runner: 0, score1_runner: 0, score2_corp: 3, label: '0-3' }
      ]
    end

    [
      { score1: 3, score2: 0, score1_corp: 0, score2_runner: 0, score1_runner: 0, score2_corp: 0, label: '3-0' },
      { score1: 0, score2: 3, score1_corp: 0, score2_runner: 0, score1_runner: 0, score2_corp: 0, label: '0-3' }
    ]
  end

  def side_options
    Pairing.sides.collect { |v, _k| [v, v] }
  end

  def side_label_for(pairing, player)
    return nil unless pairing.side && player_is_in_pairing(player, pairing)

    "(#{pairing.side_for(player).to_s.titleize})"
  end

  def player_is_in_pairing(player, pairing)
    pairing.player1_id == player.id || pairing.player2_id == player.id
  end

  def readable_score(pairing)
    return '-' if pairing.score1&.zero? && pairing.score2&.zero?

    ws = winning_side(pairing)

    if pairing.stage.single_sided_swiss?
      if pairing.player1_is_corp?
        left_score = pairing.score1
        right_score = pairing.score2
      else
        left_score = pairing.score2
        right_score = pairing.score1
      end
      return "#{left_score} - #{right_score}" unless ws

      "#{left_score} - #{right_score} (#{ws})"
    else
      return "#{pairing.score1} - #{pairing.score2}" unless ws

      "#{pairing.score1} - #{pairing.score2} (#{ws})"
    end
  end

  def winning_side(pairing)
    corp_score = (pairing.score1_corp || 0) + (pairing.score2_corp || 0)
    runner_score = (pairing.score1_runner || 0) + (pairing.score2_runner || 0)

    if (corp_score - runner_score).zero?
      nil
    elsif (corp_score - runner_score).negative?
      'R'
    else
      'C'
    end
  end
end
