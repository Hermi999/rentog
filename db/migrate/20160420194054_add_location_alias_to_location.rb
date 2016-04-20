class AddLocationAliasToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :location_alias, :string, default: ""
  end
end
