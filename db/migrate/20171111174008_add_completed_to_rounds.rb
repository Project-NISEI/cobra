# frozen_string_literal: true

class AddCompletedToRounds < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_column :rounds, :completed, :boolean, default: false
  end
end
