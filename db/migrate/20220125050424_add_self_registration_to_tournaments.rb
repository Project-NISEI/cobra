class AddSelfRegistrationToTournaments < ActiveRecord::Migration[5.2]
  def change
    add_column :tournaments, :self_registration, :boolean
  end
end
