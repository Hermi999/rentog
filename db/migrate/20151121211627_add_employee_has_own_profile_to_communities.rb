class AddEmployeeHasOwnProfileToCommunities < ActiveRecord::Migration
  def change
    add_column :communities, :employee_has_own_profile, :boolean, :default => true
  end
end
