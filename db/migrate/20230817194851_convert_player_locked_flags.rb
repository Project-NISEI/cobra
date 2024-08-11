# frozen_string_literal: true

class ConvertPlayerLockedFlags < ActiveRecord::Migration[7.0] # rubocop:disable Style/Documentation
  def change
    rename_column :players, :decks_locked, :registration_locked
    rename_column :tournaments, :all_players_decks_unlocked, :all_players_unlocked
    rename_column :tournaments, :any_player_decks_unlocked, :any_player_unlocked
  end
end
