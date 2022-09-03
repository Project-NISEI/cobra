class AddReporterToPairing < ActiveRecord::Migration[5.2]
  def change
    add_reference :pairings, :reporter, foreign_key: { to_table: :players }
  end
end
