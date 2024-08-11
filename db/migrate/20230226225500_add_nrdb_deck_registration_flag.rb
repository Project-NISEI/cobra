# frozen_string_literal: true

class AddNrdbDeckRegistrationFlag < ActiveRecord::Migration[7.0] # rubocop:disable Style/Documentation
  def change
    add_column :tournaments, :nrdb_deck_registration, :boolean, default: false
  end
end
