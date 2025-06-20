# frozen_string_literal: true

class PairingPolicy < ApplicationPolicy
  def view_decks?
    record.decks_visible_to(user)
  end

  def can_self_report?
    record.player1.user_id == user.id || record.player2.user_id == user.id
  end

end
