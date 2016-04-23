# == Schema Information
#
# Table name: company_options
#
#  id                                   :integer          not null, primary key
#  employee_has_to_give_back_listing    :boolean          default(TRUE)
#  employee_can_see_statistics          :boolean          default(TRUE)
#  pool_tool_modify_past                :boolean          default(FALSE)
#  pool_tool_group_booking_enabled      :boolean          default(FALSE)
#  created_at                           :datetime         not null
#  updated_at                           :datetime         not null
#  company_id                           :string(255)
#  pool_tool_show_all_available_devices :boolean          default(FALSE)
#  show_device_owner_per_default        :boolean          default(FALSE)
#  show_device_location_per_default     :boolean          default(FALSE)
#

class CompanyOption < ActiveRecord::Base
  # TODO Rails 4, Remove
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :company, :class_name => "Person"

  validates_length_of :company_id, :within => 1..22, :allow_nil => false

  COMPANY_OPTIONS = [
    "employee_has_to_give_back_listing",
    "pool_tool_modify_past",
    "pool_tool_show_all_available_devices",
    "show_device_owner_per_default",
    "show_device_location_per_default",
    #"employee_can_see_statistics",
    #"pool_tool_group_booking_enabled"
  ]
end
