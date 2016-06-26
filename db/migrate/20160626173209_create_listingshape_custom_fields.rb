class CreateListingshapeCustomFields < ActiveRecord::Migration
  def change
    create_table :listingshape_custom_fields do |t|
      t.belongs_to :listing_shape
      t.belongs_to :custom_field
      t.timestamps null: false
    end
  end
end
