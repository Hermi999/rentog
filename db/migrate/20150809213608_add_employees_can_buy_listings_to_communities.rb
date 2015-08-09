class AddEmployeesCanBuyListingsToCommunities < ActiveRecord::Migration
  def change
    add_column :communities, :employees_can_buy_listings, :boolean, :default => false
  end
end
