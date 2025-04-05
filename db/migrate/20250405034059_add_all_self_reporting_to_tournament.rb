# frozen_string_literal: true

class AddAllSelfReportingToTournament < ActiveRecord::Migration[7.2]
  def change
    add_column :tournaments, :allow_self_reporting, :bool, default: false
  end
end
