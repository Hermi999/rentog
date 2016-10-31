class PriceComparisonEventsController < ApplicationController
	before_filter :set_access_control_headers, only: [:create]
	before_filter :ensure_is_admin, only: [:export]

	# create new price comparison event
	# event types:
	# 	device_request	.... 	email submitted; access code will be send (not active at the moment)
	# 	device_choosen 	....	show prices button clicked	
	#   lead_generated	....	Device link clicked
	def create
		# check if daily limit is reached
		if (params[:action_type] == "device_request") and limit_request_per_day_and_ip_reached?
			render :json => {status: "error", message: "limit reached"} and return
		end

		device_name_params = params[:price_comparison_params][:device_name]
		params[:price_comparison_params][:device_name] = params[:price_comparison_params][:device_name].to_s

		ev = PriceComparisonEvent.new(price_comparison_params)
		ev.update_attribute(:ipAddress, request.ip)

		message = ""
		status = ""

		# save event
		if ev.save
			status = "success"

		# action based on event type
			# DEVICE_REQUEST (inactive)
			if params["price_comparison_params"]["action_type"] == "device_request"
				message = "Your request has been successful. You will get an email with the access code soon!"
				
				titles = device_name_params.map do |x|
					x.split("|")
				end
				titles.delete([])

				result = extract_result_from_db(titles)

				# send emails
				Delayed::Job.enqueue(PriceComparisonJob.new(ev.id, @current_community.id))

			# DEVICE_CHOOSEN
			elsif params["price_comparison_params"]["action_type"] == "device_chosen"
				# extract result
					#titles = device_name_params.map do |x|
					#	x.split("|")
					#end
					#titles.delete([])
					#result = extract_result_from_db(titles)

					device_name_params.delete("")
					result = extract_result_from_db(device_name_params)

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


	def export
    @table = PriceComparisonEvent.all.order('created_at DESC').limit(10000)

    # create new export file
    @p = Axlsx::Package.new
    @wb = @p.workbook

    # worksheet devices
    @wb.add_worksheet(:name => "Price Comparison Events") do |sheet|
      sheet.add_row PriceComparisonEvent.new.attributes.keys

      @table.each do |row|
        sheet.add_row [row.id, row.action_type, row.email, row.sessionId, row.ipAddress, row.device_name, row.device_id, row.created_at.to_date.strftime("%d.%m.%Y"), row.updated_at.to_date.strftime("%d.%m.%Y"), row.seller, row.seller_link, row.detail_1, row.detail_2, row.detail_3, row.detail_4, row.detail_5]
      end
    end

    file_name = 'price_comparison_events.xlsx'
    path_to_file = "#{Rails.root}/public/system/exportfiles/" + file_name

    @p.serialize(path_to_file)
    send_file(path_to_file, filename: file_name, type: "application/vnd.ms-excel")
  end


	private
		def price_comparison_params
			params.require(:price_comparison_params).permit(:action_type, :device_name, :device_id, :email, :sessionId, :seller, :seller_link, :seller_country, :detail_1, :detail_2, :detail_3, :detail_4, :detail_5)
		end


		def limit_request_per_day_and_ip_reached?
			requests_today = PriceComparisonEvent.where("ipAddress = ? AND created_at < ? AND created_at > ?", request.ip, DateTime.now, DateTime.now-1).count

			if requests_today > 50
				true
			else
				false
			end
		end

		def extract_result_from_db(titles)
			ret = titles.map do |title|
				#query_price_comp = nil
				#query_rentog = nil
				#q_1 = "price_cents <> '' AND "
				#q_2 = "deleted = false AND open = true AND price_cents <> '' AND "

				#if title.length > 1 
				#	query_price_comp = PriceComparisonDevice.where(q_1 + "((model LIKE ? AND manufacturer LIKE ?) OR (title LIKE ? AND title LIKE ?))", "%" + title[1].strip + "%", "%" + title[0].strip + "%", "%" + title[1].strip + "%", "%" + title[0].strip + "%")
				#	query_rentog = Listing.where(q_2 + "(title LIKE ? AND title LIKE ?)", "%" + title[1].strip + "%", "%" + title[0].strip + "%")
				#else
				#	query_price_comp = PriceComparisonDevice.where(q_1 + "(model LIKE ? OR title LIKE ?)", "%" + title[0].strip + "%", "%" + title[0].strip + "%")
				#	query_rentog = Listing.where(q_2 + "(title LIKE ?)", "%" + title[0].strip + "%")
				#end

				search_term = ThinkingSphinx::Query.escape(title)
				search_term = ThinkingSphinx::Query.wildcard(search_term)

				# prepare results from rentog database
				rentog_result = Listing.search(search_term).map do |x|
					price = x.price_cents ? (x.price_cents / 100).to_s : "On request"

					type = x.get_listing_type
					if type == "sell" || type == "rent" || type == "ad"
						
						cf_condition_id = Maybe(CustomFieldName.where(value: "condition").first).custom_field_id.or_else(nil)

						cfv_condition_id = Maybe(CustomFieldValue.where(custom_field_id: cf_condition_id, listing_id: x.id).first).id.or_else(nil)
						condition = Maybe(CustomFieldOptionSelection.where(custom_field_value_id: cfv_condition_id).first).custom_field_option.title.or_else(nil)

						currency = (price == "On request") ? "" : x.currency
						country = Maybe(ISO3166::Country.find_country_by_name(Maybe(x.author.location.address).split(",").last.gsub(/[^a-zÖÜÄüöä\s]/i, '').strip.or_else(nil))).translation(I18n.locale).or_else("") if x.author.location

						{
							model: x.title.split(" (")[0],
							manufacturer: Maybe(x.title.split(" (")[1]).sub!(")", "").or_else(nil),
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

				# prepare results from price comparison database
				result = PriceComparisonDevice.search(search_term).map do |x| 
					price = x.price_cents ? (x.price_cents / 100).to_s : "On request"
					link = x.seller_contact ? x.seller_contact : x.device_url
					if !link.empty?
						link.sub!(" ", "")
						link = "http://" + link if link.starts_with? "www."
						link = link.split("?").first + "?referrer=rentog_price_comparison_tool"
					else
						link = "#"
					end
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

				Maybe(rentog_result).or_else([]) + Maybe(result).or_else([])
			end

			ret
		end


		def set_access_control_headers
	    # TODO change this to more strict setting when done testing
	    headers['Access-Control-Allow-Origin'] = '*'
	  end
end
