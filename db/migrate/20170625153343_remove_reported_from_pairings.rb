# frozen_string_literal: true

class RemoveReportedFromPairings < ActiveRecord::Migration[5.0]
  def change
    remove_column :pairings, :reported, :boolean, default: false
  end
end
