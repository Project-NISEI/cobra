# frozen_string_literal: true

module SelfReportHelper
  def self_report_allowed(self_report, player1, player2)
    return false if current_user.nil?

    self_report.nil? &&
      ((player1&.dig('user_id') == current_user.id) ||
        (player2&.dig('user_id') == current_user.id))
  end
end
