class CreateCutConversionRates < ActiveRecord::Migration[7.2]
  def change
    create_view :cut_conversion_rates
  end
end
