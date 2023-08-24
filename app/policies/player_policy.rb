class PlayerPolicy < ApplicationPolicy
  def create?
    user
  end

  def update?
    user && (record.user == user || record.tournament.user == user)
  end

  def view_decks?
    record.decks_visible_to(user)
  end
end
