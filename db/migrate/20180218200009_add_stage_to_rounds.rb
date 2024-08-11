# frozen_string_literal: true

class AddStageToRounds < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_reference :rounds, :stage, foreign_key: true
  end
end
