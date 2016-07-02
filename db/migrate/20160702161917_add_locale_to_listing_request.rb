class AddLocaleToListingRequest < ActiveRecord::Migration
  def change
    add_column :listing_requests, :locale, :string
  end
end
