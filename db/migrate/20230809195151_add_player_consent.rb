class AddPlayerConsent < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :consent_data_sharing, :boolean
    add_column :players, :consent_deck_sharing_with_to, :boolean
    add_column :players, :consent_deck_sharing_with_opponent, :boolean
    add_column :players, :consent_streaming, :boolean
  end
end
