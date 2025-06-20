class SelfReport < ApplicationRecord
  belongs_to :pairing, touch: true

end