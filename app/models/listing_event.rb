# == Schema Information
#
# Table name: listing_events
#
#  id                  :integer          not null, primary key
#  processor_id        :string(255)      not null
#  booking_id          :integer
#  listing_id          :integer
#  event_name          :string(255)
#  send_to_subscribers :boolean          default(FALSE)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  transaction_id      :integer
#

class ListingEvent < ActiveRecord::Base
  belongs_to :processor, :class_name => "Person", :foreign_key => "processor_id"
  belongs_to :tx, :foreign_key => "transaction_id"
  belongs_to :booking, :foreign_key => "booking_id"
  belongs_to :listing, :foreign_key => "listing_id"


  def self.events_of_listing(listing_id, offset, limit)
    ListingEvent.where(:listing_id => listing_id).order(:created_at => :desc).limit(limit).offset(offset)
  end

  def self.events_of_all_company_listings(company_id, offset, limit)
    company_listings = Listing.where(:author_id => company_id)
    company_listing_ids = []
    company_listings.each {|listing| company_listing_ids << listing.id}

    ListingEvent.where('listing_id IN (?)', company_listing_ids).order(:created_at => :desc).limit(limit).offset(offset)
  end

end
