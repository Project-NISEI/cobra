class Identity < ApplicationRecord
  enum side: {
    corp: 1,
    runner: 2
  }
end
