# frozen_string_literal: true

class DropStandingsDataView < ActiveRecord::Migration[7.2]
  def change
    drop_view :standings_data_view
  end
end
