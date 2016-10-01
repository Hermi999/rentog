class PriceComparisonEventsController < ApplicationController
	before_filter :set_access_control_headers, only: [:create]

	# create new price comparison event
	def create

		# check if daily limit is reached
		if (params[:action_type] == "device_request") and limit_request_per_day_and_ip_reached?
			render :json => {status: "error", message: "limit reached"} and return
		end

		ev = PriceComparisonEvent.new(price_comparison_params)
		ev.update_attribute(:ipAddress, request.ip)

		message = ""
		status = ""

		# save event
		if ev.save
			status = "success"

			# action based on event type
			if params["price_comparison_params"]["action_type"] == "device_request"
				message = "Your request has been successful. You will get an email with the access code soon!"
				
				result = extract_result_from_db

				# send emails
				Delayed::Job.enqueue(PriceComparisonJob.new(ev.id, @current_community.id))

			elsif params["price_comparison_params"]["action_type"] == "device_chosen"
				result = extract_result_from_db

			elsif params["price_comparison_params"]["action_type"] == "lead_generated"

			end

		else
			status = "error"
			message = "failed to save"
		end
		
		render :json => {status: status, message: message, result: result} and return
	end


	# return / show all price comparison events
	def index
	end


	private
		def price_comparison_params
			params.require(:price_comparison_params).permit(:action_type, :device_name, :device_id, :email, :sessionId, :seller, :seller_link, :seller_country)
		end


		def limit_request_per_day_and_ip_reached?
			requests_today = PriceComparisonEvent.where("ipAddress = ? AND created_at < ? AND created_at > ?", request.ip, DateTime.now, DateTime.now-1).count

			if requests_today > 50
				true
			else
				false
			end
		end

		def extract_result_from_db
			# extract result
			title = params[:price_comparison_params][:device_name].split("|")
			query = ""
			query_rentog = ""

			if title.length > 1
				query = "(model LIKE '%" + title[1].strip + "%' AND manufacturer LIKE '%" + title[0].strip + "%') OR (title LIKE '%" + title[1].strip + "%' AND title LIKE '%" + title[0].strip + "%')"
				query_rentog = "title LIKE '%" + title[1].strip + "%' AND title LIKE '%" + title[0].strip + "%'"
			else
				query = "model LIKE '%" + title[0].strip + "%' OR title LIKE '%" + title[0].strip + "%'"
				query_rentog = "title LIKE '%" + title[0].strip + "%'"
			end

			# rentog database
			rentog_result = Listing.where(query_rentog + " AND deleted = false AND open = true").map do |x|
				type = x.get_listing_type
				if type == "sell" || type == "rent" || type == "ad"
					
					cf_condition_id = Maybe(CustomFieldName.where(value: "condition").first).custom_field_id.or_else(nil)

					cfv_condition_id = Maybe(CustomFieldValue.where(custom_field_id: cf_condition_id, listing_id: x.id).first).id.or_else(nil)
					condition = Maybe(CustomFieldOptionSelection.where(custom_field_value_id: cfv_condition_id).first).custom_field_option.title.or_else(nil)

					price = x.price_cents ? (x.price_cents / 100).to_s : "On request"
					currency = (price == "On request") ? "" : x.currency
					country = Maybe(ISO3166::Country.find_country_by_name(Maybe(x.author.location.address).split(",").last.gsub(/[^a-zÖÜÄüöä\s]/i, '').strip.or_else(nil))).translation(I18n.locale).or_else("")

					{
						model: x.title.split(" (")[0],
						manufacturer: x.title.split(" (")[1].sub!(")", ""),
						price: price,
						currency: x.currency.to_s,
						country: country,
						currency: currency,
						renting_price_period: x.unit_type.to_s,
						seller: "RENTOG",
						condition: condition,
						link: listing_url(x)	
					}
				end
			end

			# price comparison database
			
			
			result = PriceComparisonDevice.where(query).map do |x| 
				price = x.price_cents ? (x.price_cents / 100).to_s : "On request"
				link = x.seller_contact ? x.seller_contact : x.device_url
				link.sub!(" ", "")
				link = "http://" + link if link.starts_with? "www."
				link = link.split("?").first + "?referrer=rentog_price_comparison_tool"
				currency = (price == "On request") ? "" : x.currency
				model = x.model.to_s.empty? ? x.title.to_s : x.model.to_s

				{
					model: model,
					manufacturer: x.manufacturer.to_s,
					price: price,
					currency: x.currency.to_s,
					country: x.seller_country.to_s,
					currency: currency,
					renting_price_period: x.renting_price_period.to_s,
					seller: x.seller.to_s,
					dev_type: x.dev_type.to_s,
					condition: x.condition.to_s,
					link: link
				}
			end

			return rentog_result + result
		end


		def set_access_control_headers
	    # TODO change this to more strict setting when done testing
	    headers['Access-Control-Allow-Origin'] = '*'
	  end
end
