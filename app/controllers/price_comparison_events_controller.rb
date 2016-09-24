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

		if ev.save
			status = "success"

			if params["price_comparison_params"]["action_type"] == "device_request"
				message = "Your request has been successful. You will get an email soon!"

				# send emails
				Delayed::Job.enqueue(PriceComparisonJob.new(ev.id, @current_community.id))

			elsif params["price_comparison_params"]["action_type"] == "device_chosen"
			end

		else
			status = "error"
			message = "failed to save"
		end
		
		render :json => {status: status, message: message} and return
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


		def set_access_control_headers
	    # TODO change this to more strict setting when done testing
	    headers['Access-Control-Allow-Origin'] = '*'
	  end
end
