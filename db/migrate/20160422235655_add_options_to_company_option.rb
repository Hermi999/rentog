class AddOptionsToCompanyOption < ActiveRecord::Migration
  def change
    add_column :company_options, :show_device_owner_per_default, :boolean, default: false
    add_column :company_options, :show_device_location_per_default, :boolean, default: false
  end
end
