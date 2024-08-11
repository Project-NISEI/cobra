# frozen_string_literal: true

class AddPreviousToTournaments < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_column :tournaments, :previous_id, :integer, index: true
  end
end
