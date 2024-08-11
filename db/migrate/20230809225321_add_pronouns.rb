# frozen_string_literal: true

class AddPronouns < ActiveRecord::Migration[7.0] # rubocop:disable Style/Documentation
  def change
    add_column :players, :pronouns, :string
  end
end
