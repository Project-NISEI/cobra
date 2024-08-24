# frozen_string_literal: true

class CreateDecks < ActiveRecord::Migration[7.0]
  def change
    create_table :decks do |t|
      t.references :player, foreign_key: true
      t.string :side_id
      t.string :name
      t.string :identity_title
      t.integer :min_deck_size
      t.integer :max_influence
      t.string :nrdb_uuid
      t.string :identity_nrdb_card_id
      t.timestamps
    end
  end
end
