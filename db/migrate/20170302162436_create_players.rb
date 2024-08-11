# frozen_string_literal: true

class CreatePlayers < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    create_table :players do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.string :name
      t.references :tournament, foreign_key: true
    end
  end
end
