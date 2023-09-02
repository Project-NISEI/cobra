class AddStreamingConsent < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :allow_streaming_opt_out, :boolean
    add_column :players, :stream_swiss_games, :boolean, default: true
  end
end
