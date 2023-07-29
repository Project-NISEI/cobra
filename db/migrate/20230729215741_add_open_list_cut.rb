class AddOpenListCut < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :open_list_cut, :boolean, default: false
  end
end
