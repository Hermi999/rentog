class AddCreditsToPerson < ActiveRecord::Migration
  def change
    add_column :people, :credits, :integer, :default => 0
  end
end
