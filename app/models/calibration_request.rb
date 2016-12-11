# == Schema Information
#
# Table name: calibration_requests
#
#  id                               :integer          not null, primary key
#  job_type                         :string(255)      not null
#  manufac_model                    :string(255)
#  device_type                      :string(255)
#  device_quantity                  :integer
#  device_additional_info           :string(255)
#  device_measuring_chain_desc      :string(255)
#  device_project_desc              :string(255)
#  special_calibration_requirements :string(255)      not null
#  type_of_calibration              :string(255)      not null
#  calibration_logistics            :string(255)      not null
#  specific_calibration_details     :string(255)
#  company_name                     :string(255)      not null
#  company_country                  :string(255)      not null
#  company_address                  :string(255)
#  email_address                    :string(255)      not null
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#

class CalibrationRequest < ActiveRecord::Base
end
