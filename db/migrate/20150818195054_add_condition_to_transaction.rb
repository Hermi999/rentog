class AddConditionToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :condition, :string
  end
end
