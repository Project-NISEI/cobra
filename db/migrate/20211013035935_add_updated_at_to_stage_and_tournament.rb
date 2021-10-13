class AddUpdatedAtToStageAndTournament < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :stages, null: false, default: -> { 'NOW()' }
    add_column :tournaments, :updated_at, :datetime
  end
end
