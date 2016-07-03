class AddAttributesToPerson < ActiveRecord::Migration
  def change
    add_column :people, :description_of_sales_conditions, :string
    add_column :people, :contact_email, :string
    add_column :people, :website, :string
  end
end
