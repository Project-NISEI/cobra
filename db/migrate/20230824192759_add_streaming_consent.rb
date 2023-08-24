class AddStreamingConsent < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :ask_for_streaming_consent, :boolean
    add_column :players, :consented_to_be_streamed, :boolean
  end
end
