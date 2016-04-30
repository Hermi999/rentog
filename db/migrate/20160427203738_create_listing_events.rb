class CreateListingEvents < ActiveRecord::Migration
  def change
    create_table :listing_events do |t|
      t.string :processor_id, null: false
      t.integer :booking_id
      t.integer :listing_id
      t.string :event_name
      t.boolean :send_to_subscribers, default: false
      t.timestamps null: false
    end
  end
end
