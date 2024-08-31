# frozen_string_literal: true

class AddManualSeedToPlayers < ActiveRecord::Migration[5.2]
  def change
    add_column :players, :manual_seed, :integer
  end
end
