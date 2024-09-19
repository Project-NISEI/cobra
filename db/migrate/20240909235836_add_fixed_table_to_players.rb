# frozen_string_literal: true

class AddFixedTableToPlayers < ActiveRecord::Migration[7.1]
  def change
    add_column :players, :fixed_table_number, :integer
  end
end
