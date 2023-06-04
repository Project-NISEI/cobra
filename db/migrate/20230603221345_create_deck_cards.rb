class CreateDeckCards < ActiveRecord::Migration[7.0]
  def change
    create_table :deck_cards do |t|
      t.references :deck, foreign_key: true
      t.string :name
      t.integer :quantity
      t.integer :influence
      t.timestamps
    end
  end
end
