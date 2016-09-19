# == Schema Information
#
# Table name: price_comparison_events
#
#  id          :integer          not null, primary key
#  action_type :string(255)      default("device_chosen"), not null
#  email       :string(255)
#  sessionId   :string(255)      not null
#  ipAddress   :string(255)      not null
#  device_name :string(255)
#  device_id   :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class PriceComparisonEvent < ActiveRecord::Base
end
