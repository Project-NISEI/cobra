# frozen_string_literal: true

class AddDecksLockedFlags < ActiveRecord::Migration[7.0] # rubocop:disable Style/Documentation
  def change
    add_column :players, :decks_locked, :boolean
    add_column :tournaments, :all_players_decks_unlocked, :boolean, default: true
    add_column :tournaments, :any_player_decks_unlocked, :boolean, default: true
  end
end
