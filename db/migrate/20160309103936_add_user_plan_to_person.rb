class AddUserPlanToPerson < ActiveRecord::Migration
  def change
    add_column :people, :user_plan, :string, :default => "free"
    add_column :people, :user_plan_features, :string
  end
end
