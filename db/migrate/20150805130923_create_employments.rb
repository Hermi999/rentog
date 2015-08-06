class CreateEmployments < ActiveRecord::Migration
  def change
    create_table :employments do |t|
      t.string :company_id
      t.string :employee_id

      t.timestamps
    end
    add_index :employments, :company_id
    add_index :employments, :employee_id
  end
end
