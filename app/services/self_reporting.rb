# frozen_string_literal: true

module SelfReporting
  # A user is allowed to report a pairing when:
  #   a. the user is logged in
  #   b. has not already reported
  #   c. is part of the pairing
  def self.self_report_allowed(current_user, current_existing_self_report, player1_user_id, player2_user_id)
    return false if current_user.nil?

    current_existing_self_report.nil? &&
      ((player1_user_id == current_user.id) ||
        (player2_user_id == current_user.id))
  end
end
