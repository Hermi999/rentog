class CreateCreditConfigurations < ActiveRecord::Migration
  def change
    create_table :credit_configurations do |t|
      t.integer :community_id, :null => false
      t.integer :credits_register, :null => false, :default => 0
      t.integer :credits_new_device, :null => false, :default => 0
      t.integer :credits_customer_request, :null => false, :default => 0
      t.integer :credits_request, :null => false, :default => 0
      t.integer :credits_referal_registration, :null => false, :default => 0
      t.integer :credits_referal_seller, :null => false, :default => 0
      t.integer :credits_referal_seller_days, :null => false, :default => 0
      t.integer :credits_referal_social_media, :null => false, :default => 0
      t.integer :credits_buy_in, :null => false, :default => 0
      t.integer :credits_free, :null => false, :default => 0
      t.integer :credits_admin_changed, :null => false, :default => 0
      t.integer :credits_present, :null => false, :default => 0
      t.integer :credits_listings_still_visible, :null => false, :default => 0
      t.timestamps null: false
    end

    Community.all.each do |com|
      conf = CreditConfiguration.new(community_id: com.id)
      conf.save!
    end
  end
end
