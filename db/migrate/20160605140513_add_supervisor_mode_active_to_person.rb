class AddSupervisorModeActiveToPerson < ActiveRecord::Migration
  def change
    add_column :people, :supervisor_mode_active, :boolean, default: false
  end
end
