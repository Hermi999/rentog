class CreatePriceComparisonDevices < ActiveRecord::Migration
  def change
    create_table :price_comparison_devices do |t|
    	t.string :device_url, null: false
    	t.string :manufacturer
    	t.string :model
    	t.string :title
    	t.string :category_a
    	t.string :category_b
    	t.integer :price_cents
    	t.string :currency
    	t.string :seller
    	t.string :provider
    	t.string :dev_type		# renting, selling
    	t.string :condition		# new, used
      t.timestamps null: false
    end
  end
end
