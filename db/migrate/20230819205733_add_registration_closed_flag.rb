# frozen_string_literal: true

class AddRegistrationClosedFlag < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :registration_closed, :boolean
  end
end
