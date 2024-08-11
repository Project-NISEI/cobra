# frozen_string_literal: true

class AddAutocompleteToIdentities < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_column :identities, :autocomplete, :string
  end
end
