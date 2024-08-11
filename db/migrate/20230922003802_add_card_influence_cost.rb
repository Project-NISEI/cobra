# frozen_string_literal: true

class AddCardInfluenceCost < ActiveRecord::Migration[7.0] # rubocop:disable Style/Documentation
  def change
    add_column :deck_cards, :influence_cost, :integer
  end
end
