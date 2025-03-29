# frozen_string_literal: true

class TournamentType < ApplicationRecord
  has_many :tournaments
end
