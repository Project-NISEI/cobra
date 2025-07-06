# frozen_string_literal: true

class AddByePointsToStandingRows < ActiveRecord::Migration[7.2]
  def change
    add_column :standing_rows, :bye_points, :integer, default: 0
  end
end
