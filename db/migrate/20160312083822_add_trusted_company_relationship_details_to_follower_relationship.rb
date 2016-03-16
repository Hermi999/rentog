class AddTrustedCompanyRelationshipDetailsToFollowerRelationship < ActiveRecord::Migration
  def change
    add_column :follower_relationships, :trust_level, :string, :default => "trust_admin_and_employees"
    add_column :follower_relationships, :shipment_necessary, :boolean, :default => false
    add_column :follower_relationships, :payment_necessary, :boolean, :default => false
  end
end
