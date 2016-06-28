class CreateListingRequests < ActiveRecord::Migration
  def change
    create_table :listing_requests do |t|
      t.integer :listing_id
      t.string :person_id
      t.string :name
      t.string :email
      t.string :phone
      t.string :country
      t.string :message
      t.boolean :contact_per_phone
      t.boolean :get_further_docs
      t.boolean :get_price_list
      t.boolean :get_quotation
      t.datetime :reply_time

      t.timestamps null: false
    end
  end
end
