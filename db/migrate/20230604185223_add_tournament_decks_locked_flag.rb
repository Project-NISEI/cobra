class AddTournamentDecksLockedFlag < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :decks_locked, :boolean
  end
end
