# frozen_string_literal: true

class AddRegistrationClosedFlag < ActiveRecord::Migration[7.0] # rubocop:disable Style/Documentation
  def change
    add_column :tournaments, :registration_closed, :boolean
  end
end
