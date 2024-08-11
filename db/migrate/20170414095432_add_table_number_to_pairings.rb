# frozen_string_literal: true

class AddTableNumberToPairings < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_column :pairings, :table_number, :integer
  end
end
