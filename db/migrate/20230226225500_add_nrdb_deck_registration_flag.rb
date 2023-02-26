class AddNrdbDeckRegistrationFlag < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :nrdb_deck_registration, :boolean, default: false
  end
end
