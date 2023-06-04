class Deck < ApplicationRecord
  belongs_to :player
  has_many :deck_cards, dependent: :destroy

  def as_view
    {details: self, cards: deck_cards}
  end
end
