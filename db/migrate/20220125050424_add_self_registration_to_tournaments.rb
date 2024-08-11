# frozen_string_literal: true

class AddSelfRegistrationToTournaments < ActiveRecord::Migration[5.2] # rubocop:disable Style/Documentation
  def change
    add_column :tournaments, :self_registration, :boolean
  end
end
