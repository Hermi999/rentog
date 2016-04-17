# == Schema Information
#
# Table name: credit_configurations
#
#  id                             :integer          not null, primary key
#  community_id                   :integer          not null
#  credits_register               :integer          default(0), not null
#  credits_new_device             :integer          default(0), not null
#  credits_customer_request       :integer          default(0), not null
#  credits_request                :integer          default(0), not null
#  credits_referal_registration   :integer          default(0), not null
#  credits_referal_seller         :integer          default(0), not null
#  credits_referal_seller_days    :integer          default(0), not null
#  credits_referal_social_media   :integer          default(0), not null
#  credits_buy_in                 :integer          default(0), not null
#  credits_free                   :integer          default(0), not null
#  credits_admin_changed          :integer          default(0), not null
#  credits_present                :integer          default(0), not null
#  credits_listings_still_visible :integer          default(0), not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#

class CreditConfiguration < ActiveRecord::Base
  belongs_to :community
end
