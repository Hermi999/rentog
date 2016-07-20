class ListingRequestsController < ApplicationController

  before_filter :ensure_is_admin, only: [:index, :export]

  # not needed at the moment
  def show
  end

  def index
    @current_page = params[:page] || 1
    @listing_requests = ListingRequest.all.paginate(:page => @current_page, :per_page => @per_page).order('created_at DESC')
    @per_page = 15
  end

  def export
    @listing_requests = ListingRequest.all.order('created_at DESC').limit(10000)

    # create new export file
    @p = Axlsx::Package.new
    @wb = @p.workbook

    # worksheet devices
    @wb.add_worksheet(:name => "ListingRequests") do |sheet|
      sheet.add_row ListingRequest.new.attributes.keys

      @listing_requests.each do |row|
        new_row = []
        row.attributes.each do |field|
          new_row <<
          if field[0] == "listing_id" && field[1] != 0
            listing_ = Listing.find(field[1])
            "Title: " + listing_.title + "\r\nID: " + listing_.id.to_s + "\r\Owner: " + listing_.author.full_name
          else
            field[1].to_s
          end
        end

        sheet.add_row new_row
      end
    end

    file_name = 'listing_requests.xlsx'
    path_to_file = "#{Rails.root}/public/system/exportfiles/" + file_name

    @p.serialize(path_to_file)
    send_file(path_to_file, filename: file_name, type: "application/vnd.ms-excel")
  end

  def create
    # limit requests per ip address
    params[:listing_request][:ip_address] = request.remote_ip
    requests_this_day = ListingRequest.where("ip_address = (?) and created_at < (?) and created_at > (?)", "127.0.0.1", Date.today+1, Date.today-1).count

    if requests_this_day < 26

      # translate country to english
      params[:listing_request][:country] = Maybe(ISO3166::Country.find_country_by_name(params[:listing_request][:country])).translation('en').or_else(nil)

      # get locale of user
      params[:listing_request][:locale] = I18n.locale

      # try to create new listing request
      lr = ListingRequest.new(listing_request_params)

      save_request_in_cookies

      # check Google Recapture response
      if verify_captcha(lr) && lr.save

        # add listing_request to visitor/person and vice versia
        if @visitor
          @visitor.listing_requests << lr
          @visitor.update_attributes(name: lr.name, email: lr.email, phone: lr.phone, country: lr.country)
          lr.visitor = @visitor

        elsif @current_user
          @current_user.listing_requests << lr
          lr.person = @current_user
        end

        # send emails to customer & seller
        Delayed::Job.enqueue(ListingRequestJob.new(lr.id, @current_community.id))

        # respond
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

  # not needed at the moment
  def update
  end


  private

    def listing_request_params
      params.require(:listing_request).permit(:listing_id, :name, :email, :country, :person_id, :phone, :message, :get_further_docs, :contact_per_phone, :get_price_list, :get_quotation, :ip_address, :locale, :last1name)
    end

    def save_request_in_cookies
      cookies.permanent[:listing_request_name] = params[:listing_request][:name]
      cookies.permanent[:listing_request_email] = params[:listing_request][:email]
      cookies.permanent[:listing_request_country] = params[:listing_request][:country]
      cookies.permanent[:listing_request_phone] = params[:listing_request][:phone]
      cookies.permanent[:listing_request_message] = params[:listing_request][:message] unless params[:listing_request][:listing_id] == "abcd"
      cookies.permanent[:listing_request_get_further_docs] = params[:listing_request][:get_further_docs]
      cookies.permanent[:listing_request_contact_per_phone] = params[:listing_request][:contact_per_phone]
      cookies.permanent[:listing_request_get_price_list] = params[:listing_request][:get_price_list]
      cookies.permanent[:listing_request_get_quotation] = params[:listing_request][:get_quotation]
    end

    def verify_captcha(listing_request)
      res = false

      # Already verified that this user is a human
      if cookies[:captcha_id] == Digest::SHA256.digest(request.remote_ip + "adsf23zafds16").gsub(/\W+/, '')
        res = true

      elsif params[:gRecaptchaResponse] == "abcd" && params[:listing_request][:listing_id] == "abcd"
        # request to rentog. no re-captcha.
        res = true
      else
        res = verify_recaptcha(model: listing_request, response: params[:gRecaptchaResponse])
        cookies[:captcha_id] = {value: Digest::SHA256.digest(request.remote_ip + "adsf23zafds16").gsub(/\W+/, ''), :expires => 24.hour.from_now } if res
      end

      res
    end

end
