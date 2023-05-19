class CreatePrintings < ActiveRecord::Migration[7.0]
  def change
    create_table :printings do |t|
      t.string :nrdb_id
      t.string :nrdb_card_id
    end
    add_index :printings, :nrdb_id, unique: true
  end
end
