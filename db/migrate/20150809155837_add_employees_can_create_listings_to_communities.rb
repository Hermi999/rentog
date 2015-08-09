class AddEmployeesCanCreateListingsToCommunities < ActiveRecord::Migration
  def change
    add_column :communities, :employees_can_create_listings, :boolean, :default => false
  end
end
