class AddOnlyPoolToolToCommunities < ActiveRecord::Migration
  def change
    add_column :communities, :only_pool_tool, :boolean, :default => false
  end
end
