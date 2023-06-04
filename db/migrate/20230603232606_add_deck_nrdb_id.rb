class AddDeckNrdbId < ActiveRecord::Migration[7.0]
  def change
    add_column :decks, :nrdb_id, :integer
  end
end
