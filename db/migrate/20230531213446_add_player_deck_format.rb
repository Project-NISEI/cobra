class AddPlayerDeckFormat < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :corp_deck_format, :string
    add_column :players, :runner_deck_format, :string
  end
end
