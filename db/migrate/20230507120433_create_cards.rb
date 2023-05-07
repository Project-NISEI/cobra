class CreateCards < ActiveRecord::Migration[7.0]
  def change
    create_table :cards do |t|
      t.string :nrdb_code
      t.string :title
      t.string :side_code
      t.string :faction_code
      t.string :type_code
    end
  end
end
