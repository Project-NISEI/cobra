# frozen_string_literal: true

class AddIdTwoForOneToPairing < ActiveRecord::Migration[7.0] # rubocop:disable Style/Documentation
  def change
    add_column :pairings, :intentional_draw, :boolean, default: false, null: false
    add_column :pairings, :two_for_one, :boolean, default: false, null: false
  end
end
