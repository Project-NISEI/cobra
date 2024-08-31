# frozen_string_literal: true

class AddDateToTournaments < ActiveRecord::Migration[5.0]
  def change
    add_column :tournaments, :date, :date
  end
end
