class AddOthersCanSeeEmployeesToCommunities < ActiveRecord::Migration
  def change
    add_column :communities, :others_can_see_employees, :boolean, :default => false
  end
end
