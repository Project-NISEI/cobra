# frozen_string_literal: true

class AddStreamUrlToTournaments < ActiveRecord::Migration[5.2] # rubocop:disable Style/Documentation
  def change
    add_column :tournaments, :stream_url, :string
  end
end
