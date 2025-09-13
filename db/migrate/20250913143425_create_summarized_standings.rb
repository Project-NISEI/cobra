# frozen_string_literal: true

class CreateSummarizedStandings < ActiveRecord::Migration[7.2]
  def change
    create_view :summarized_standings
  end
end
