class AddUserRefToPlayers < ActiveRecord::Migration[5.2]
  def change
    add_reference :players, :user, foreign_key: true
  end
end
