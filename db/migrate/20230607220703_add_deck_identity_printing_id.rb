# frozen_string_literal: true

class AddDeckIdentityPrintingId < ActiveRecord::Migration[7.0] # rubocop:disable Style/Documentation
  def change
    add_column :decks, :identity_nrdb_printing_id, :string
  end
end
