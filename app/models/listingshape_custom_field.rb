# == Schema Information
#
# Table name: listingshape_custom_fields
#
#  id               :integer          not null, primary key
#  listing_shape_id :integer
#  custom_field_id  :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class ListingshapeCustomField < ActiveRecord::Base
  belongs_to :listing_shape
  belongs_to :custom_field
end
