class SetOnlyOrangizationDefault < ActiveRecord::Migration
  def up
    change_column :communities, :only_organizations, :boolean, :default => 1
  end

  def down
    change_column :communities, :only_organizations, :boolean
  end
end
