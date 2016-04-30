class CreateListingSubscribersTable < ActiveRecord::Migration
  def self.up
    create_table :listing_subscribers do |t|
      t.integer :listing_id
      t.string :person_id

      t.timestamps
    end
  end

  def self.down
    drop_table :listing_subscribers
  end
end
