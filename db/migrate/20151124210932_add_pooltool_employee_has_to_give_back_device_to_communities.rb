class AddPooltoolEmployeeHasToGiveBackDeviceToCommunities < ActiveRecord::Migration
  def change
    add_column :communities, :pooltool_employee_has_to_give_back_device, :boolean, :default => false
  end
end
