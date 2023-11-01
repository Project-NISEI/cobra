class StandingRow < ApplicationRecord
  belongs_to :stage
  belongs_to :player

  default_scope { order(position: :asc) }

  delegate :name, :pronouns, :name_with_pronouns, :manual_seed, to: :player

  def corp_identity
    player.corp_identity_object
  end

  def runner_identity
    player.runner_identity_object
  end

end
