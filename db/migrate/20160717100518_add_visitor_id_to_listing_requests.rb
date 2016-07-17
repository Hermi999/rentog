class AddVisitorIdToListingRequests < ActiveRecord::Migration
  def change
    add_column :listing_requests, :visitor_id, :integer
  end
end
