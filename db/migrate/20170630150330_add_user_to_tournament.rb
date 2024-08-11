# frozen_string_literal: true

class AddUserToTournament < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_reference :tournaments, :user, foreign_key: true
  end
end
