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
#  ip_address        :string(255)
#  locale            :string(255)
#  visitor_id        :integer
#

class ListingRequest < ActiveRecord::Base
  belongs_to :listing, :class_name => "Listing", :foreign_key => "listing_id"
  belongs_to :person, :class_name => "Person", :foreign_key => "person_id"
  belongs_to :visitor, :class_name => "Visitor", :foreign_key => "visitor_id"

  delegate :author, to: :listing

  attr_accessor :last1name   # for bot detection

  validates :ip_address, presence: true
  validates :last1name, absence: true
  validates :listing_id, :name, :email, :country, presence: true
  validates :contact_per_phone, presence: true, allow_blank: true
  validates :get_further_docs, presence: true, allow_blank: true
  validates :get_price_list, presence: true, allow_blank: true
  validates :get_quotation, presence: true, allow_blank: true


  def self.count_requests_of_listing(listing_id)
    ListingRequest.where(listing_id: listing_id).count
  end


  def self.requests_of_company(company_id)
    person = Person.where(id: company_id).first
    requests = []

    person.listings.where.each do |listing|
      requests << ListingRequest.where(listing_id: listing_id)
    end

    requests
  end

end
