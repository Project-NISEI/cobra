class AddPublicListCutFlag < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :public_list_cut, :boolean, default: false
  end
end
