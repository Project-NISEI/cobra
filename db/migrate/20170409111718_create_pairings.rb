# frozen_string_literal: true

class CreatePairings < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    create_table :pairings do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references :round, foreign_key: true
    end
  end
end
