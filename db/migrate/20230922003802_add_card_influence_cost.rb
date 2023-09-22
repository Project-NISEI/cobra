class AddCardInfluenceCost < ActiveRecord::Migration[7.0]
  def change
    add_column :deck_cards, :influence_cost, :integer
  end
end
