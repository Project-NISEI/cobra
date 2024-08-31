# frozen_string_literal: true

class CreateRounds < ActiveRecord::Migration[5.0]
  def change
    create_table :rounds do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references :tournament, foreign_key: true
      t.integer :number
    end
  end
end
