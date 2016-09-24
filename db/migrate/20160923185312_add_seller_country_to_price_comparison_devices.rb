class AddSellerCountryToPriceComparisonDevices < ActiveRecord::Migration
  def change
    add_column :price_comparison_devices, :seller_country, :string
  end
end
