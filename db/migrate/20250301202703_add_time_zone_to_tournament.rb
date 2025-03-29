# frozen_string_literal: true

class AddTimeZoneToTournament < ActiveRecord::Migration[7.2]
  def change
    add_column :tournaments, :time_zone, :string
  end
end
