# frozen_string_literal: true

class AddSideToPairing < ActiveRecord::Migration[5.0] # rubocop:disable Style/Documentation
  def change
    add_column :pairings, :side, :integer
  end
end
