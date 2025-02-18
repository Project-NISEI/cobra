# frozen_string_literal: true

class UpdateCutConversionRatesToVersion2 < ActiveRecord::Migration[7.2]
  def change
    update_view :cut_conversion_rates, version: 2, revert_to_version: 1
  end
end
