class AddDeckCardsPrintingId < ActiveRecord::Migration[7.0]
  def change
    add_column :deck_cards, :nrdb_printing_id, :string
  end
end
