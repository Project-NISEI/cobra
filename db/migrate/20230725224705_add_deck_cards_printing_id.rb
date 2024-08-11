# frozen_string_literal: true

class AddDeckCardsPrintingId < ActiveRecord::Migration[7.0] # rubocop:disable Style/Documentation
  def change
    add_column :deck_cards, :nrdb_printing_id, :string
  end
end
