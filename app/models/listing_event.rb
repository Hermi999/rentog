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


  # register listing view event only if
  #   -) the current logged in user has not already viewed this listing
  #   -) the logged out user has not already viewed this listing
  def self.listing_viewed(listing, current_user, cookies)
    session_key_name = Rails.application.config.session_options[:key]
    processor = Maybe(current_user).id.or_else(cookies[session_key_name])

    if processor
      if ListingEvent.where(processor_id: processor, listing_id: listing.id, event_name: "listing_viewed_unique").count == 0
        ListingEvent.create({processor_id: processor, listing_id: listing.id, event_name: "listing_viewed_unique"})
        listing.update_attribute(:times_viewed, listing.times_viewed + 1)
      end
    else
      ListingEvent.create({processor_id: "unknown", listing_id: listing.id, event_name: "listing_viewed_unique"})
      listing.update_attribute(:times_viewed, listing.times_viewed + 1)
    end
  end


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
