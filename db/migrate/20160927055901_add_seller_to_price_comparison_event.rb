class AddSellerToPriceComparisonEvent < ActiveRecord::Migration
  def change
    add_column :price_comparison_events, :seller, :string
    add_column :price_comparison_events, :seller_link, :string
  end
end
