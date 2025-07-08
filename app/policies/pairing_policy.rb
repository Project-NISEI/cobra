# frozen_string_literal: true

class PairingPolicy < ApplicationPolicy
  def view_decks?
    record.decks_visible_to(user)
  end

  def can_self_report?
    SelfReporting.self_report_allowed(user,
                                      record.self_reports.find do |self_report|
                                        self_report.report_player_id == user.id
                                      end,
                                      record.player1.user_id,
                                      record.player2.user_id)
  end
end
