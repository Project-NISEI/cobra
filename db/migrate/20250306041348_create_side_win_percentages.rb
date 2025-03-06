class CreateSideWinPercentages < ActiveRecord::Migration[7.2]
  def change
    create_view :side_win_percentages
  end
end
