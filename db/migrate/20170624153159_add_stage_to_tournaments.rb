# frozen_string_literal: true

class AddStageToTournaments < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_column :tournaments, :stage, :integer, default: 0
  end
end
