# frozen_string_literal: true

class RemovePairingSortFromTournaments < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    remove_column :tournaments, :pairing_sort, :integer, default: 0
  end
end
