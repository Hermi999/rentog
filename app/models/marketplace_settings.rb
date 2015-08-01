class MarketplaceSettings < ActiveRecord::Base
  attr_accessible :community, :shipping_enabled
  belongs_to :community
end
