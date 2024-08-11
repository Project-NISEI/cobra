# frozen_string_literal: true

class AddDeckUserId < ActiveRecord::Migration[7.0] # rubocop:disable Style/Documentation
  def change
    add_reference :decks, :user
    Deck.all.find_each do |deck|
      deck.update(user_id: deck.player.user_id)
    end
  end
end
