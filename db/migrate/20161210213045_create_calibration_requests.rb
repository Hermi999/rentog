class CreateCalibrationRequests < ActiveRecord::Migration
  def change
    create_table :calibration_requests do |t|
      t.string  :job_type, null: false
      t.string  :manufac_model
      t.string  :device_type
      t.integer :device_quantity
      t.string  :device_additional_info
      t.string  :device_measuring_chain_desc
      t.string  :device_project_desc
      t.string  :special_calibration_requirements, null: false
      t.string  :type_of_calibration, null: false
      t.string  :calibration_logistics, null: false
      t.string  :specific_calibration_details
      t.string  :company_name, null: false
      t.string  :company_country, null: false
      t.string  :company_address
      t.string  :email_address, null: false

      t.timestamps null: false
    end
  end
end
