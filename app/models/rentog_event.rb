# == Schema Information
#
# Table name: rentog_events
#
#  id             :integer          not null, primary key
#  person_id      :string(255)
#  other_party_id :string(255)
#  event_name     :string(255)
#  event_details  :string(255)
#  send_to_admins :boolean
#  rentog_version :integer
#  split_test_id  :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  visitor_id     :integer
#  event_result   :string(255)
#

class RentogEvent < ActiveRecord::Base
  belongs_to :visitor, class_name: "Visitor", foreign_key: "visitor_id"
  belongs_to :person, class_name: "Person", foreign_key: "person_id"
  has_one :other_party, class_name: "Person", foreign_key: "other_party_id"

  before_create :set_rentog_version
  def set_rentog_version
    self.rentog_version = Maybe(APP_CONFIG).rentog_version.or_else(nil)
  end
end
