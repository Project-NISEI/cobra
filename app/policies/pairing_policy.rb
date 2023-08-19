class PairingPolicy < ApplicationPolicy
  def view_decks?
    record.cut_decks_visible_to(user)
  end
end
