class PlayerPolicy < ApplicationPolicy
  def create?
    user
  end

  def update?
    user && (record.user_id == user.id || record.tournament.user == user)
  end
end
