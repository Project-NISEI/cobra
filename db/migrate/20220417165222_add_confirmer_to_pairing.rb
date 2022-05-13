class AddConfirmerToPairing < ActiveRecord::Migration[5.2]
  def change
    add_reference :pairings, :confirmer, foreign_key: { to_table: :players }
  end
end
