# frozen_string_literal: true

class AddPrivateToTournaments < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_column :tournaments, :private, :boolean, default: false
  end
end
