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
#  seller      :string(255)
#  seller_link :string(255)
#  detail_1    :string(255)
#  detail_2    :string(255)
#  detail_3    :string(255)
#  detail_4    :string(255)
#  detail_5    :string(255)
#

class PriceComparisonEvent < ActiveRecord::Base
end
