class AddDeckUserId < ActiveRecord::Migration[7.0]
  def change
    add_reference :decks, :user
  end
end
