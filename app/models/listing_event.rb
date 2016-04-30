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
end
