# == Schema Information
#
# Table name: visitors
#
#  id             :integer          not null, primary key
#  session_id     :string(255)
#  name           :string(255)
#  email          :string(255)
#  phone          :string(255)
#  company        :string(255)
#  country        :string(255)
#  ip_address     :string(255)
#  count_sessions :integer          default(0)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  locale         :string(255)      default("en")
#

class Visitor < ActiveRecord::Base
  has_many :listing_requests
  has_many :rentog_events
  has_many :listing_events
end
