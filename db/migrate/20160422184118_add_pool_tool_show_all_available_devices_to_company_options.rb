class AddPoolToolShowAllAvailableDevicesToCompanyOptions < ActiveRecord::Migration
  def change
    add_column :company_options, :pool_tool_show_all_available_devices, :boolean, default: false
  end
end
