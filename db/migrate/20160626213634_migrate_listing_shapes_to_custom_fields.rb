class MigrateListingShapesToCustomFields < ActiveRecord::Migration
  def change
    CustomField.all.each do |field|
      field.listing_shapes << ListingShape.where(deleted: false)
    end
  end
end
