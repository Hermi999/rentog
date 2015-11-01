class AddTargetToInvitations < ActiveRecord::Migration
  def change
    add_column :invitations, :target, :string, :default => "employee"
  end
end
