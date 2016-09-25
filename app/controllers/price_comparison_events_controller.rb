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
			params.require(:price_comparison_params).permit(:action_type, :device_name, :device_id, :email, :sessionId)
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
			model = 
				if title.length > 1
					title[1].strip
				else
					title[0].strip
				end
			
			result = PriceComparisonDevice.where("model LIKE ?", model).map do |x| 
				price = x.price_cents ? (x.price_cents / 100).to_s : "On request"
				link = x.provider ? x.seller_contact : x.device_url

				{
					model: x.model.to_s,
					manufacturer: x.manufacturer.to_s,
					price: price,
					currency: x.currency.to_s,
					country: x.seller_country.to_s,
					currency: x.currency,
					seller: x.seller.to_s,
					dev_type: x.dev_type.to_s,
					condition: x.condition.to_s,
					link: link
				}
			end

			return result
		end


		def set_access_control_headers
	    # TODO change this to more strict setting when done testing
	    headers['Access-Control-Allow-Origin'] = '*'
	  end
end
