# frozen_string_literal: true

class Deck < ApplicationRecord
  belongs_to :player
  belongs_to :user
  has_many :deck_cards, dependent: :destroy
  has_many :cards, class_name: 'DeckCard'

  def as_view(user)
    { details: attributes.merge({ mine: self.user == user, player_name: player.name }), cards: cards.sort_by(&:title) }
  end
end
