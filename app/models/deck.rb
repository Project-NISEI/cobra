class Deck < ApplicationRecord
  belongs_to :player
  belongs_to :user
  has_many :deck_cards, dependent: :destroy
  alias_attribute :cards, :deck_cards

  def as_view(user)
    { details: self.attributes.merge({ mine: self.user == user }), cards: cards }
  end
end
