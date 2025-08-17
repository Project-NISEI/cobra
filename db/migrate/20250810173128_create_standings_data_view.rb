# frozen_string_literal: true

class CreateStandingsDataView < ActiveRecord::Migration[7.2]
  def change
    create_view :standings_data_view
  end
end
