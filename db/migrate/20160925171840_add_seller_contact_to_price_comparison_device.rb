class AddSellerContactToPriceComparisonDevice < ActiveRecord::Migration
  def change
    add_column :price_comparison_devices, :seller_contact, :string
  end
end
