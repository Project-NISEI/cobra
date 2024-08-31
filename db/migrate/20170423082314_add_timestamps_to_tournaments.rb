# frozen_string_literal: true

class AddTimestampsToTournaments < ActiveRecord::Migration[5.0]
  def change
    add_column :tournaments, :created_at, :datetime
  end
end
