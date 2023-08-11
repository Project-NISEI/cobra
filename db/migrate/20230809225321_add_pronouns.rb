class AddPronouns < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :pronouns, :string
  end
end
