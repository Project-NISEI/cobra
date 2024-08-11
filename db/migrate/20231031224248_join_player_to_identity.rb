# frozen_string_literal: true

class JoinPlayerToIdentity < ActiveRecord::Migration[7.0] # rubocop:disable Style/Documentation
  def change
    add_reference :players, :corp_identity_ref, foreign_key: { to_table: :identities }
    add_reference :players, :runner_identity_ref, foreign_key: { to_table: :identities }
    identities = Identity.all.index_by(&:name)
    Player.all.find_each do |player|
      player.update_columns(corp_identity_ref_id: identities[player.corp_identity]&.id, # rubocop:disable Rails/SkipsModelValidations
                            runner_identity_ref_id: identities[player.runner_identity]&.id)
    end
  end
end
