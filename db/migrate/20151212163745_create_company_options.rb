class CreateCompanyOptions < ActiveRecord::Migration
  def up
    create_table :company_options do |t|
      t.boolean :employee_has_to_give_back_listing, :default => true
      t.boolean :employee_can_see_statistics, :default => true
      t.boolean :pool_tool_modify_past, :default => false
      t.boolean :pool_tool_group_booking_enabled, :default => false

      t.timestamps
    end
  end

  def down
    drop_table :company_options
  end
end
