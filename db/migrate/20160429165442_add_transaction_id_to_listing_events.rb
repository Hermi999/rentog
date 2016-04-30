class AddTransactionIdToListingEvents < ActiveRecord::Migration
  def change
    add_column :listing_events, :transaction_id, :integer
  end
end
