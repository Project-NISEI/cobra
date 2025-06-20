class CreateSelfReports < ActiveRecord::Migration[7.2]
  def change
    create_table :self_reports do |t|
      t.integer :pairing_id
      t.integer :report_player_id
      t.integer :score1
      t.integer :score2
      t.integer :score1_corp
      t.integer :score1_runner
      t.integer :score2_corp
      t.integer :score2_runner
      t.boolean :intentional_draw
      t.index [:pairing_id], name: "index_self_reports_on_pairings"
    end
    add_foreign_key :self_reports, :pairings, column: :pairing_id
  end
end
