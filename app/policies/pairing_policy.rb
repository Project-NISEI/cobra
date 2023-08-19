class PairingPolicy < ApplicationPolicy
  def view_decks?
    if record.tournament.user == user
      return true
    end
    unless record.stage.double_elim?
      return false
    end
    if @tournament.open_list_cut?
      user == record.player1.user || user == record.player2.user
    else
      @tournament.public_list_cut?
    end
  end
end
