class Deck < ApplicationRecord
  belongs_to :player
  has_many :deck_cards, dependent: :destroy
end
