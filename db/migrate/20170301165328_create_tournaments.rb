# frozen_string_literal: true

class CreateTournaments < ActiveRecord::Migration[5.0]
  def change
    create_table :tournaments do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.string :name
    end
  end
end
