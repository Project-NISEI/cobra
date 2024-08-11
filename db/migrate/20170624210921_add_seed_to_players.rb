# frozen_string_literal: true

class AddSeedToPlayers < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_column :players, :seed, :integer
  end
end
