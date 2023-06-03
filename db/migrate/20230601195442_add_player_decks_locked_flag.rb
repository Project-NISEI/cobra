class AddPlayerDecksLockedFlag < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :decks_locked, :boolean
  end
end
