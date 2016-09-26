class AddRentingPricePeriodToPriceComparisonDevice < ActiveRecord::Migration
  def change
    add_column :price_comparison_devices, :renting_price_period, :string
  end
end
