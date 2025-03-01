# frozen_string_literal: true

class AddLatestCardSetToTournament < ActiveRecord::Migration[7.2]
  add_reference :tournaments, :card_set, type: :string, foreign_key: { to_table: :card_sets }
end
