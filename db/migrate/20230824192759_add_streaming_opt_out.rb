# frozen_string_literal: true

class AddStreamingOptOut < ActiveRecord::Migration[7.0] # rubocop:disable Style/Documentation
  def change
    add_column :tournaments, :allow_streaming_opt_out, :boolean
    add_column :players, :include_in_stream, :boolean, default: true
  end
end
