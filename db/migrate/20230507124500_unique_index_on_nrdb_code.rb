class UniqueIndexOnNrdbCode < ActiveRecord::Migration[7.0]
  def change
    remove_index :cards, :nrdb_code
    add_index :cards, :nrdb_code, unique: true
    add_index :identities, :nrdb_code, unique: true
  end
end
