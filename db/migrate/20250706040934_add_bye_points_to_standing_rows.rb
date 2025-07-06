# frozen_string_literal: true

class AddByePointsToStandingRows < ActiveRecord::Migration[7.2]
  def up
    add_column :standing_rows, :bye_points, :integer, default: 0
    connection.exec_update <<-SQL
      UPDATE standing_rows
      SET bye_points = points - (corp_points + runner_points)
      WHERE points <> (corp_points + runner_points)
    SQL
  end

  def down
    remove_column :standing_rows, :bye_points
  end
end
