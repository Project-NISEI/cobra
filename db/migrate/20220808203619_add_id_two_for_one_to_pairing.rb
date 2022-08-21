class AddIdTwoForOneToPairing < ActiveRecord::Migration[6.1]
  def change
    add_column :pairings, :intentional_draw, :boolean
    add_column :pairings, :two_for_one, :boolean
  end
end
