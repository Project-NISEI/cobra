# frozen_string_literal: true

class RemoveStatusFromTournaments < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    remove_column :tournaments, :status, :integer, default: 0
  end
end
