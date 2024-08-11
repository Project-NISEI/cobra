# frozen_string_literal: true

class AddSideScoresToPairings < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_column :pairings, :score1_runner, :integer
    add_column :pairings, :score1_corp, :integer
    add_column :pairings, :score2_corp, :integer
    add_column :pairings, :score2_runner, :integer
  end
end
