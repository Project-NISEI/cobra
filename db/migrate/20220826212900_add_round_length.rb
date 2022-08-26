class AddRoundLength < ActiveRecord::Migration[7.0]
  def change
    add_column :rounds, :length_minutes, :integer
  end
end
