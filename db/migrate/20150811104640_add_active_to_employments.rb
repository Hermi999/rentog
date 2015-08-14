class AddActiveToEmployments < ActiveRecord::Migration
  def change
    add_column :employments, :active, :boolean, :default => false
  end
end
