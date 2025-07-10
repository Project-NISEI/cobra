# frozen_string_literal: true

class AddByePointsToStandingRows < ActiveRecord::Migration[7.2]
  def up
    add_column :standing_rows, :bye_points, :integer, default: 0

    # This SQL is complicated because tournaments with cuts will have players listed in multiple stages.
    # We need to limit the update only to stages with byes for each player.
    connection.exec_update <<-SQL
      UPDATE
        standing_rows sr
        SET bye_points = b.bye_points
      FROM (
        SELECT s.id as stage_id,
          s.number as stage_number,
          COALESCE(p.player1_id, p.player2_id) AS player_id,
          COALESCE(p.score1, p.score2) AS bye_points
        FROM pairings p
          INNER JOIN rounds r ON p.round_id = r.id
          INNER JOIN stages s ON r.stage_id = s.id
        WHERE
          (p.player1_id IS NULL OR p.player2_id IS NULL)
          AND
          (p.score1 > 0 OR p.score2 > 0)
      ) b
      WHERE
        sr.player_id = b.player_id
        AND sr.stage_id = b.stage_id;
    SQL
  end

  def down
    remove_column :standing_rows, :bye_points
  end
end
