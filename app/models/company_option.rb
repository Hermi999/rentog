# == Schema Information
#
# Table name: company_options
#
#  id                                :integer          not null, primary key
#  employee_has_to_give_back_listing :boolean          default(TRUE)
#  employee_can_see_statistics       :boolean          default(TRUE)
#  pool_tool_modify_past             :boolean          default(FALSE)
#  pool_tool_group_booking_enabled   :boolean          default(FALSE)
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  company_id                        :string(255)
#

class CompanyOption < ActiveRecord::Base
  attr_accessible :employee_can_see_statistics,
                  :employee_has_to_give_back_listing,
                  :pool_tool_group_booking_enabled,
                  :pool_tool_modify_past,
                  :company_id

  belongs_to :company, :class_name => "Person"

  validates_length_of :company_id, :within => 1..22, :allow_nil => false


end
