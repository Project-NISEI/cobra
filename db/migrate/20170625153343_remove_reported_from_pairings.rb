# frozen_string_literal: true

class RemoveReportedFromPairings < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    remove_column :pairings, :reported, :boolean, default: false
  end
end
