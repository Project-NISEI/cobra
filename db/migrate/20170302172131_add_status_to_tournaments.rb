# frozen_string_literal: true

class AddStatusToTournaments < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_column :tournaments, :status, :integer, default: 0
  end
end
