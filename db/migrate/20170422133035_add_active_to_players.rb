# frozen_string_literal: true

class AddActiveToPlayers < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_column :players, :active, :boolean, default: true
  end
end
