# frozen_string_literal: true

class CreateIdentities < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    create_table :identities do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.string :name
      t.integer :side
      t.string :faction
    end
    add_index :identities, :side
  end
end
