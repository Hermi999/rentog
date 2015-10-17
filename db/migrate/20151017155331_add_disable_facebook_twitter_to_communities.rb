class AddDisableFacebookTwitterToCommunities < ActiveRecord::Migration
  def change
    add_column :communities, :disable_facebook_twitter, :boolean, :default => false
  end
end
