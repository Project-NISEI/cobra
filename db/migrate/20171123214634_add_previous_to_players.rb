# frozen_string_literal: true

class AddPreviousToPlayers < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_column :players, :previous_id, :integer, index: true
  end
end
