class AddDeckVisibility < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :swiss_deck_visibility, :integer, default: 0, null: false
    add_column :tournaments, :cut_deck_visibility, :integer, default: 0, null: false
    remove_column :tournaments, :open_list_cut
  end
end
