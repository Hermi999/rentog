class AddCompanyIdToCompanyOptions < ActiveRecord::Migration
  def change
    add_column :company_options, :company_id, :string
  end
end
