# frozen_string_literal: true

class AddManualSeedToTournaments < ActiveRecord::Migration[5.2] # rubocop:disable Style/Documentation
  def change
    add_column :tournaments, :manual_seed, :boolean
  end
end
