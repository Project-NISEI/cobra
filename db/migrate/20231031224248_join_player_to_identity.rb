class JoinPlayerToIdentity < ActiveRecord::Migration[7.0]
  def change
    add_reference :players, :corp_identity_ref, foreign_key: { to_table: :identities }
    add_reference :players, :runner_identity_ref, foreign_key: { to_table: :identities }
    Player.all.each do |player|
      player.update(corp_identity_ref_id: Identity.find_by(name: player.corp_identity)&.id)
      player.update(runner_identity_ref_id: Identity.find_by(name: player.runner_identity)&.id)
    end
  end
end
