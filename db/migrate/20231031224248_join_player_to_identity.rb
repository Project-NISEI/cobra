class JoinPlayerToIdentity < ActiveRecord::Migration[7.0]
  def change
    add_reference :players, :corp_identity_ref, foreign_key: { to_table: :identities }
    add_reference :players, :runner_identity_ref, foreign_key: { to_table: :identities }
    identities = Identity.all.index_by(&:name)
    Player.all.each do |player|
      player.update_columns(corp_identity_ref_id: identities[player.corp_identity]&.id,
                            runner_identity_ref_id: identities[player.runner_identity]&.id)
    end
  end
end
