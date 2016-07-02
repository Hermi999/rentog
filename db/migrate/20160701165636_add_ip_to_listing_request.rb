class AddIpToListingRequest < ActiveRecord::Migration
  def change
    add_column :listing_requests, :ip_address, :string
  end
end
