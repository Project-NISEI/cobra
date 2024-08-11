# frozen_string_literal: true

class AddNrdbCodeToIdentities < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_column :identities, :nrdb_code, :string
  end
end
