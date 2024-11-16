# frozen_string_literal: true

class FixRoundsTournamentId < ActiveRecord::Migration[7.2]
  def up
    # Set tournament id which had been missing.
    Round.all.each do |r| # rubocop:disable Rails/FindEach
      r.tournament_id = r.stage.tournament_id
      r.save
    end

    change_column :rounds, :tournament_id, :int, null: false
  end

  def down
    change_column :rounds, :tournament_id, :int, null: true

    Round.all.each do |r| # rubocop:disable Rails/FindEach
      r.tournament_id = nil
      r.save
    end
  end
end
