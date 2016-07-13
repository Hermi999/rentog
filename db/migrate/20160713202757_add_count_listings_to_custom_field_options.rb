class AddCountListingsToCustomFieldOptions < ActiveRecord::Migration
  def change
    add_column :custom_field_options, :count_listings, :integer
  end
end
