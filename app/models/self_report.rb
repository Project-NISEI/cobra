# frozen_string_literal: true

class SelfReport < ApplicationRecord
  belongs_to :pairing, touch: true

  before_save :normalise_scores_before_save

  def normalise_scores_before_save
    # Handle score presets set as corp & runner scores
    combine_separate_side_scores
  end

  def combine_separate_side_scores
    return unless (score1_corp.present? && score1_corp.positive?) ||
                  (score1_runner.present? && score1_runner.positive?) ||
                  (score2_corp.present? && score2_corp.positive?) ||
                  (score2_runner.present? && score2_runner.positive?)

    self.score1 = (score1_corp || 0) + (score1_runner || 0)
    self.score2 = (score2_corp || 0) + (score2_runner || 0)
  end
end
