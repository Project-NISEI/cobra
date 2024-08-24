# frozen_string_literal: true

class AddSlugToTournament < ActiveRecord::Migration[5.0]
  def change
    add_column :tournaments, :slug, :string, index: { unique: true }
  end
end
