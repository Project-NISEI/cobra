# frozen_string_literal: true

class AddCardTypeAndFaction < ActiveRecord::Migration[7.0]
  def change
    add_column :decks, :faction_id, :string
    add_column :deck_cards, :card_type_id, :string
    add_column :deck_cards, :faction_id, :string
  end
end
