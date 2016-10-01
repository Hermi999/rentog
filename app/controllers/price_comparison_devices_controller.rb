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
			# delete all devs from provider
			if params[:devices].first[1]["delete_all_from_provider"] 
				if params[:devices].first[1]["provider"] != ""
					prov = params[:devices].first[1]["provider"]
				  PriceComparisonDevice.where(provider: prov).delete_all
				else
					PriceComparisonDevice.where(provider: nil).delete_all
					PriceComparisonDevice.where(provider: "").delete_all
				end
			end

			# create new devs
			params[:devices].each do |dev|		
				begin
					dev[1].except!("delete_all_from_provider")
					PriceComparisonDevice.create(dev[1].permit(:device_url, :model, :manufacturer, :title, :category_a, :category_b, :currency, :price_cents, :condition, :dev_type, :seller, :seller_country, :seller_contact, :provider, :renting_price_period))
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

			# Rentog Listing
			rentog_devs = Listing.where("title LIKE ? AND open = true AND deleted = false", search_param).map do |x|
				manufacturer = Maybe(x.title.split(" (")[1]).sub!(")", "").or_else("")
				model = x.title.split(" (")[0]
				if manufacturer 
					manufacturer + " | " + model
				else
					model
				end
			end


			if params[:search_term].length < 3
				devices = PriceComparisonDevice.select(:model, :manufacturer, :title).limit(50).where("model LIKE ? OR manufacturer LIKE ? OR title LIKE ?", search_param,search_param,search_param).map do |x|
					if x.model.present? and x.manufacturer.present?
						x.manufacturer + " | " + x.model
					elsif x.model.present?
						x.model
					else
						x.title
					end
				end
			else
				devices = PriceComparisonDevice.select(:model, :manufacturer, :title).where("model LIKE ? OR manufacturer LIKE ? OR title LIKE ?", search_param, search_param, search_param).map do |x|
					if x.model.present? and x.manufacturer.present?
						x.manufacturer + " | " + x.model
					elsif x.model.present?
						x.model
					else
						x.title
					end
				end
			end
		else
			devices = ""
		end

		# remove duplicates
		devices = (rentog_devs + devices).uniq

		# return answer as json
		render :json => {devices: devices} and return
	end



	private

		def set_access_control_headers
	    # TODO change this to more strict setting when done testing
	    headers['Access-Control-Allow-Origin'] = '*'
	  end
end
