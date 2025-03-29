# frozen_string_literal: true

class AddOfficialPrizeKitIdToTournament < ActiveRecord::Migration[7.2]
  add_reference :tournaments, :official_prize_kit, foreign_key: { to_table: :official_prize_kits }, null: true
end
