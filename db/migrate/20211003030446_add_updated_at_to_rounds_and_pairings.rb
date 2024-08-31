# frozen_string_literal: true

class AddUpdatedAtToRoundsAndPairings < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :rounds, null: false, default: -> { 'NOW()' }
    add_timestamps :pairings, null: false, default: -> { 'NOW()' }
  end
end
