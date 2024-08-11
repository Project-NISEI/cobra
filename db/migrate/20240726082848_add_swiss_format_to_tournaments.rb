# frozen_string_literal: true

class AddSwissFormatToTournaments < ActiveRecord::Migration[7.1] # rubocop:disable Style/Documentation
  def change
    add_column :tournaments, :swiss_format, :integer, default: 0, null: false
  end
end
