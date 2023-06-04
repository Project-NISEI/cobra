class AddTournamentDecksLockedFlag < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :all_players_decks_unlocked, :boolean, default: true
    add_column :tournaments, :any_player_decks_unlocked, :boolean, default: true
  end
end
