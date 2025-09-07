# frozen_string_literal: true

class UpdateStandingsDataViewToVersion2 < ActiveRecord::Migration[7.2]
  def change
    update_view :standings_data_view, version: 2, revert_to_version: 1
  end
end
