# == Schema Information
#
# Table name: price_comparison_devices
#
#  id                   :integer          not null, primary key
#  device_url           :string(255)      not null
#  manufacturer         :string(255)
#  model                :string(255)
#  title                :string(255)
#  category_a           :string(255)
#  category_b           :string(255)
#  price_cents          :integer
#  currency             :string(255)
#  seller               :string(255)
#  provider             :string(255)
#  dev_type             :string(255)
#  condition            :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  seller_country       :string(255)
#  seller_contact       :string(255)
#  renting_price_period :string(255)
#

class PriceComparisonDevice < ActiveRecord::Base

  before_create do
    existing = PriceComparisonDevice.where(device_url: self.device_url).first
    existing.delete if existing

    self.manufacturer.sub!("|", ";") if self.manufacturer
    self.model.sub!("|", ";") if self.model
  end

end
