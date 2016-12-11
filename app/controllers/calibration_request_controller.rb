class CalibrationRequestController < ApplicationController
  before_filter :set_access_control_headers, only: [:create]

  def create

    # Check if your_name is empty --> little bot detection
    if params[:your_name] == ""
      # save to db
      params.delete :your_name
      cal_req = CalibrationRequest.new(params.permit(:job_type, :manufac_model, :device_type, :device_quantity, :device_additional_info, :device_project_desc, :device_measuring_chain_desc, :special_calibration_requirements, :specific_calibration_details, :type_of_calibration, :company_name, :company_country, :company_address, :email_address, :calibration_logistics))
      
      if cal_req.save
        # send emails
        Delayed::Job.enqueue(CalibrationRequestJob.new(cal_req.id, @current_community.id))
      end

      status = "Success!"
    else
      status = "success..."
    end

    respond_to do |format|
      format.json { render :json => {status: status} }
    end
  end

  private

    def set_access_control_headers
      # TODO change this to more strict setting when done testing
      if ENV["RAILS_ENV"] == "development"
        headers['Access-Control-Allow-Origin'] = '*'
      else
        headers['Access-Control-Allow-Origin'] = '*.rentog.com'
      end
    end
end
