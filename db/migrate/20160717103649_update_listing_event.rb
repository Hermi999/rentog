class UpdateListingEvent < ActiveRecord::Migration
  def change
    add_column :listing_events, :visitor_id, :integer
    change_column :listing_events, :processor_id, :string, :null => true
    rename_column :listing_events, :processor_id, :person_id
  end
end
