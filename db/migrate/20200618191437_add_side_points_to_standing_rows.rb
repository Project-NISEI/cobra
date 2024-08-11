# frozen_string_literal: true

class AddSidePointsToStandingRows < ActiveRecord::Migration[5.2] # rubocop:disable Style/Documentation
  def change
    add_column :standing_rows, :corp_points, :integer
    add_column :standing_rows, :runner_points, :integer
  end
end
