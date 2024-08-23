# frozen_string_literal: true

class PairingPolicy < ApplicationPolicy
  def view_decks?
    record.decks_visible_to(user)
  end
end
