# frozen_string_literal: true

class AddRoundLength < ActiveRecord::Migration[7.0]
  def change
    add_column :rounds, :length_minutes, :integer, default: 65
  end
end
