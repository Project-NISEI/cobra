# frozen_string_literal: true

class User < ApplicationRecord
  has_many :tournaments

  def flipper_id
    nrdb_username
  end
end
