class MakePlayerNamesUnique < ActiveRecord::Migration[7.2]
  def change
    # Add a "(duplicate #N)"" suffix to any duplicate player names before applying the index.
    dupes = Player.select(:tournament_id, :name)
                  .group(:tournament_id, :name)
                  .having('COUNT(*) > 1')
    dupes.each do |dupe|
      players = Player.where(tournament_id: dupe.tournament_id, name: dupe.name)
      players.each_with_index do |player, index|
        player.update!(name: "#{player.name} (duplicate ##{index + 1})")
      end
    end
    add_index :players, %i[tournament_id name], unique: true, name: 'idx_uniq_players_tournament_id_name'
  end
end
