class CreateDecks < ActiveRecord::Migration[7.0]
  def change
    create_table :decks do |t|
      t.references :player, foreign_key: true
      t.string :side
      t.string :name
      t.string :identity
      t.integer :min_deck_size
      t.integer :max_influence
      t.timestamps
    end
  end
end
