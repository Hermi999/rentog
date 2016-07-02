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
#

require 'rails_helper'

RSpec.describe ListingRequest, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
