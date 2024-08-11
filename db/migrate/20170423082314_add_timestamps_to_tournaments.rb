# frozen_string_literal: true

class AddTimestampsToTournaments < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_column :tournaments, :created_at, :datetime
  end
end
