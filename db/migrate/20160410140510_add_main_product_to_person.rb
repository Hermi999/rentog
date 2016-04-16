class AddMainProductToPerson < ActiveRecord::Migration
  def change
    add_column :people, :main_product, :string  # only for companies
  end
end
