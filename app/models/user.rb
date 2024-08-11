class User < ApplicationRecord
  has_many :tournaments

  def flipper_id
    nrdb_username
  end
end
