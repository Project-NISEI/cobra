# frozen_string_literal: true

class CreateDeckCards < ActiveRecord::Migration[7.0]
  def change
    create_table :deck_cards do |t|
      t.references :deck, foreign_key: true
      t.string :title
      t.integer :quantity
      t.integer :influence
      t.string :nrdb_card_id
      t.timestamps
    end
  end
end
