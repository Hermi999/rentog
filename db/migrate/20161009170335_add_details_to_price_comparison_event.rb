class AddDetailsToPriceComparisonEvent < ActiveRecord::Migration
  def change
    add_column :price_comparison_events, :detail_1, :string
    add_column :price_comparison_events, :detail_2, :string
    add_column :price_comparison_events, :detail_3, :string
    add_column :price_comparison_events, :detail_4, :string
    add_column :price_comparison_events, :detail_5, :string
  end
end
