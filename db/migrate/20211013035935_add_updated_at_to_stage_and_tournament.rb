# frozen_string_literal: true

class AddUpdatedAtToStageAndTournament < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :stages, null: false, default: -> { 'NOW()' }
    add_column :tournaments, :updated_at, :datetime, null: false, default: -> { 'NOW()' }
  end
end
