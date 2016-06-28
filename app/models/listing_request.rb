# == Schema Information
#
# Table name: listing_requests
#
#  id                :integer          not null, primary key
#  listing_id        :integer
#  person_id         :string(255)
#  name              :string(255)
#  email             :string(255)
#  phone             :string(255)
#  country           :string(255)
#  message           :string(255)
#  contact_per_phone :boolean
#  get_further_docs  :boolean
#  get_price_list    :boolean
#  get_quotation     :boolean
#  reply_time        :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class ListingRequest < ActiveRecord::Base
  belongs_to :listing, :class_name => "Listing", :foreign_key => "listing_id"
  belongs_to :registered_user, :class_name => "Person", :foreign_key => "person_id"

  delegate :author, to: :listing
end
