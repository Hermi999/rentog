class ListingRequestsController < ApplicationController

  def show
  end

  def create
    # limit requests per ip address
    params[:listing_request][:ip_address] = request.remote_ip
    requests_this_day = ListingRequest.where("ip_address = (?) and created_at < (?) and created_at > (?)", "127.0.0.1", Date.today+1, Date.today-1).count

    if requests_this_day < 26

      # translate country to english
      params[:listing_request][:country] = Maybe(ISO3166::Country.find_country_by_name(params[:listing_request][:country])).translation('en').or_else(nil)

      # try to create new listing request
      lr = ListingRequest.new(listing_request_params)

      save_request_in_cookies

      # check Google Recapture response
      if verify_captcha(lr) && lr.save

        respond_to do |format|
          format.json { render :json => {response: "success"} }
        end
      else
        errors = Maybe(lr).errors.or_else(nil) || "Recapture error"
        respond_to do |format|
          format.json { render :json => {response: "error", message: errors} }
        end
      end

    else
      respond_to do |format|
        format.json { render :json => {response: "error", error_message: t("listings.show.limit_listing_requests")} }
      end
    end
  end

  def update
  end


  private

    def listing_request_params
      params.require(:listing_request).permit(:listing_id, :name, :email, :country, :person_id, :phone, :message, :get_further_docs, :contact_per_phone, :get_price_list, :get_quotation, :ip_address)
    end

    def save_request_in_cookies
      cookies.permanent[:listing_request_name] = params[:listing_request][:name]
      cookies.permanent[:listing_request_email] = params[:listing_request][:email]
      cookies.permanent[:listing_request_country] = params[:listing_request][:country]
      cookies.permanent[:listing_request_phone] = params[:listing_request][:phone]
      cookies.permanent[:listing_request_message] = params[:listing_request][:message]
      cookies.permanent[:listing_request_get_further_docs] = params[:listing_request][:get_further_docs]
      cookies.permanent[:listing_request_contact_per_phone] = params[:listing_request][:contact_per_phone]
      cookies.permanent[:listing_request_get_price_list] = params[:listing_request][:get_price_list]
      cookies.permanent[:listing_request_get_quotation] = params[:listing_request][:get_quotation]
    end

    def verify_captcha(listing_request)
      res = false
      if cookies[:captcha_id] == Digest::SHA256.digest(request.remote_ip + "adsf23zafds16").gsub(/\W+/, '')
        res = true
      else
        res = verify_recaptcha(model: listing_request, response: params[:gRecaptchaResponse])
        cookies[:captcha_id] = {value: Digest::SHA256.digest(request.remote_ip + "adsf23zafds16").gsub(/\W+/, ''), :expires => 24.hour.from_now } if res
      end

      res
    end
end
