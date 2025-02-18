# frozen_string_literal: true

class UpdateCutConversionRatesToVersion3 < ActiveRecord::Migration[7.2]
  def change
    update_view :cut_conversion_rates, version: 3, revert_to_version: 2
  end
end
