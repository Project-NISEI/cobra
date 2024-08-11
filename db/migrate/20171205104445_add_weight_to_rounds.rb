# frozen_string_literal: true

class AddWeightToRounds < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_column :rounds, :weight, :decimal, default: 1.0
  end
end
