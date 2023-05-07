class AddPlayerDeck < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :corp_deck, :jsonb
    add_column :players, :runner_deck, :jsonb
  end
end
