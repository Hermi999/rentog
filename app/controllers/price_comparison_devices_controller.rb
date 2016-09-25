class PriceComparisonDevicesController < ApplicationController
	before_filter :set_access_control_headers, only: [:index]

	before_filter :ensure_is_admin, only: [:new, :create, :update]

	# show import page
	def new
	end

	# create new device
	def create
		status = "success"
		details = []

		if params[:devices]
			params[:devices].each do |dev|		
				begin
					PriceComparisonDevice.create(dev[1].permit(:device_url, :model, :manufacturer, :title, :category_a, :category_b, :currency, :price_cents, :condition, :dev_type, :seller, :seller_country, :seller_contact, :provider))
				rescue ActiveRecord::ActiveRecordError
					# simply skip this entry and return error message to browser
					status = "error"
					details << "Couldn't upload device with attributes: " + dev.to_s
				end
			end
		end

		render :json => {status: status, details: details} and return
	end



	# update existing devices
	def update

	end

	# show/return devices
	def index
		if params[:search_term]
			search_param = "%" + params[:search_term] + "%"

			if params[:search_term].length < 3
				devices = PriceComparisonDevice.select(:model, :manufacturer).limit(50).where("model LIKE ? OR manufacturer LIKE ?", search_param,search_param).map do |x|
					if x.model.present? and x.manufacturer.present?
						x.manufacturer + " | " + x.model
					elsif x.model.present?
						x.model
					else
						#x.manufacturer
					end
				end
			else
				devices = PriceComparisonDevice.select(:model, :manufacturer).where("model LIKE ? OR manufacturer LIKE ?", search_param, search_param).map do |x|
					if x.model.present? and x.manufacturer.present?
						x.manufacturer + " | " + x.model
					elsif x.model.present?
						x.model
					else
						#x.manufacturer
					end
				end
			end
		else
			devices = ""
		end

		# remove duplicates
		devices = devices.uniq

		# return answer as json
		render :json => {devices: devices} and return
	end



	private

		def set_access_control_headers
	    # TODO change this to more strict setting when done testing
	    headers['Access-Control-Allow-Origin'] = '*'
	  end
end
