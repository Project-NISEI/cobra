class CreateRoundTimerActivations < ActiveRecord::Migration[7.0]
  def change
    create_table :round_timer_activations do |t|
      t.references :tournament, foreign_key: true
      t.references :round, foreign_key: true
      t.datetime :start_time, null: false, default: -> { 'NOW()' }
      t.datetime :stop_time
    end
  end
end
