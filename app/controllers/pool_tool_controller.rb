class PoolToolController < ApplicationController
  # Filters
  before_filter :ensure_is_authorized_to_view, :only => [ :show, :get_theme, :set_theme, :return_device]

  def show
    # @company_owner is the person which owns the company
    @company_owner = Person.find(params[:person_id] || params[:id])

    # Get all company transactions (joined with listings and bookings) from database, ordered by listings.id
    transactions = Transaction.joins(:listing, :booking, :starter).select(" transactions.id as transaction_id,
                                                                            listings.id as listing_id,
                                                                            listings.title as title,
                                                                            listings.availability as availability,
                                                                            listings.created_at,
                                                                            bookings.start_on as start_on,
                                                                            bookings.end_on as end_on,
                                                                            bookings.reason as reason,
                                                                            bookings.description as description,
                                                                            bookings.device_returned as device_returned,
                                                                            transactions.current_state,
                                                                            people.given_name as renter_given_name,
                                                                            people.family_name as renter_family_name,
                                                                            people.username as renting_entity_username,
                                                                            people.organization_name as renting_entity_organame,
                                                                            people.id as renter_id")
                                                                  .where("  listings.author_id = ? AND
                                                                            transactions.community_id = ? AND
                                                                            listings.open = '1' AND
                                                                            (listings.availability = 'all' OR listings.availability = 'intern' OR listings.availability = 'trusted') AND
                                                                            (listings.valid_until IS NULL OR valid_until > ?)",
                                                                            @company_owner.id, @current_community.id, DateTime.now)
                                                                  .order("  listings.id asc")
    # Convert ActiveRecord Relation into array of hashes
    transaction_array = transactions.as_json

    # Get only bookings which are booked by the user AND are currently in state active (that means the user hadn't give them back) AND are past, but the user did not return them
    user_bookings = transactions.where("people.id = ? AND ((bookings.start_on <= ? AND bookings.end_on >= ? AND bookings.device_returned = false) OR (bookings.end_on < ? AND bookings.device_returned = false))", @current_user.id, Date.today, Date.today, Date.today)
    @user_bookings_array = user_bookings.as_json

    # Get all open Listings of the current user
    # @open_listings = Listing.currently_open.where("listings.author_id" => @company_owner)
    search = {
      author_id: @company_owner.id,
      include_closed: false,
      page: 1,
      per_page: 200,
      availability: Listing::VALID_AVAILABILITY_OPTIONS
    }

    includes = [:author, :listing_images]
    listings = ListingIndexService::API::Api.listings.search(community_id: @current_community.id, search: search, includes: includes).and_then { |res|
      Result::Success.new(
        ListingIndexViewUtils.to_struct(
        result: res,
        includes: includes,
        page: search[:page],
        per_page: search[:per_page],
      ))
    }.data

    # Only use certain fields in JS
    open_listings_array = []
    listings.each do |listing|
      small_image = listing.listing_images.first.small_3x2 if listing.listing_images.first
      open_listings_array << {  name: listing.title,
                                desc: listing.availability,
                                availability: listing.availability,
                                listing_id: listing.id,
                                created_at: listing.created_at,
                                image: small_image }
    end
    # Convert all the transaction into a jquery-Gantt readable source.
    # wah: This might be shifted to the client (javascript) in future, since
    # it would reduce load on the server
    devices = []
    act_transaction = {}
    prev_listing_id = 0, counter = -1

    transaction_array.each do |transaction|
      renter = get_renter_and_relation(transaction)

      if transaction['reason']
        renting_entity = transaction['reason']
      elsif transaction['renting_entity_organame'] != "" && transaction['renting_entity_organame'] != nil
        renting_entity = transaction['renting_entity_organame']
      else
        renting_entity = transaction['renter_family_name'] + " " + transaction['renter_given_name']
      end


      if prev_listing_id != transaction['listing_id']
        # new Listing, new transaction
        counter = counter + 1

        transaction['name'] = transaction['title']
        transaction['desc'] = transaction['availability']
        transaction['already_booked_dates'] = Listing.already_booked_dates(transaction['listing_id'], @current_community)
        transaction['values'] = [{
          'from' => "/Date(" + transaction['start_on'].to_time.to_i.to_s + "000)/",
          'to' => "/Date(" + transaction['end_on'].to_time.to_i.to_s + "000)/",
          'label' => renting_entity,
          'customClass' =>  "gantt_" + renter[:relation],
          'transaction_id' => transaction['transaction_id'],
          'renter_id' => transaction['renter_id'],
          'description' => transaction['description']
        }]
        # Remove unused keys from hash
        transaction.except!('title', 'start_on', 'end_on', 'renting_entity_username', 'renting_entity_organame', 'transaction_id', 'renter_family_name', 'renter_given_name', 'renter_id')

        prev_listing_id = transaction['listing_id']
        act_transaction = transaction
        devices << transaction

      else
        # Previous Listing, new transaction
        newTrans = {
          'from' => "/Date(" + transaction['start_on'].to_time.to_i.to_s + "000)/",
          'to' => "/Date(" + transaction['end_on'].to_time.to_i.to_s + "000)/",
          'label' => renting_entity,
          'customClass' => "gantt_" + renter[:relation],
          'transaction_id' => transaction['transaction_id'],
          'renter_id' => transaction['renter_id'],
          'description' => transaction['description']
        }
        devices[counter]['values'] << newTrans
      end
    end

    # Variables which should be send to JavaScript
    poolTool_gon_vars(devices, open_listings_array)

    render locals: { listings: listings }
  end

  # get the current theme of the user from the db
  def get_theme
    respond_to do |format|
      format.json { render :json => {theme: @current_user.pool_tool_color_schema} }
    end
  end

  # sets the choosen theme of the user in the db
  def set_theme
    # Save in db
    @current_user.update_attribute :pool_tool_color_schema, params['theme']

    respond_to do |format|
      format.json { render :json => {theme: @current_user.pool_tool_color_schema} }
    end
  end


  private

    def ensure_is_authorized_to_view
      # Rentog Admin is authorized
      return if @current_user && @current_user.has_admin_rights_in?(@current_community)

      # if organization
      if @current_user and @current_user.is_organization
        # ALLOWED: Company Admin is authorized to view own pool tool
        if @current_user.username == params['person_id']
          return

        # NOT ALLOWED: View another companies pool tool --> Redirect
        else
          flash[:error] = t("pool_tool.you_have_to_be_company_member")
          redirect_to person_poolTool_path(@current_user) and return false
        end


      # if employee
      elsif @current_user and @current_user.is_employee?
        # Get company who's pool tool page should be accessed
        comp = Person.where(:username => params['person_id']).first

        # NOT ALLOWED (but no error):
        # employee tries to access own pool tool via employee id. That's not
        # possible -> Redirect to company pool tool page without error message
        if @current_user.username == params['person_id']
          redirect_to person_poolTool_path(@current_user.company) and return

        # ALLOWED: Company employee is authorized to view his companies pool tool page
        elsif comp && @current_user.is_employee_of?(comp.id)
          return

        # NOT ALLOWED: Employee accessing another companies pool tool --> Redirect to own pool tool
        else
          flash[:error] = t("pool_tool.you_have_to_be_company_member")
          redirect_to person_poolTool_path(@current_user.company) and return false
        end

      # If not logged in
      else
        # NOT ALLOWED: Signed out user tries to access any pool tool page --> Redirect to login
        flash[:error] = t("pool_tool.you_have_to_be_company_member")
        redirect_to login_path and return false
      end
    end


    # returns what relation a specific transaction has to the company
    def get_renter_and_relation(transaction)
      # How is the relation between the company & the renter of this one listing?
        renter = Person.where(id: transaction["renter_id"]).first
        if renter.is_organization
          # Company is renting listing
          if @company_owner.follows?(renter)
            # Other company is trusted by the company
            relation = "trustedCompany"
          elsif renter == @company_owner
            relation = "otherReason"
          else
            # Other company is not trusted by the company
            relation = "anyCompany"
          end
        else
          # Any Employee is renting listing
          if renter.is_employee_of?(@company_owner.id)
            # Own employee is renting listing
            relation = "ownEmployee"
          else
            # Employee of another company is renting listing
            relation = "anyEmployee"
          end
        end

        # If renter is the current user
        if renter == @current_user
          relation = relation + "_me"
        end

        { renter: renter, relation: relation }
    end

    # sets all variables which are needed in Javascript on the client side
    def poolTool_gon_vars(devices, open_listings_array)
      # Variables which should be send to JavaScript
      days =    [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
      months =  [:january, :february, :march, :april, :may, :june, :july, :august, :september, :october, :november, :december]

      gon.push({
        devices: devices,                             # holds listings with transactions (values) for gantt chart and also the already_booked_dates for the calendar
        open_listings: open_listings_array,           # holds all listings (even those with no transactions)
        user_active_bookings: @user_bookings_array,   # holds the currently open bookings of the user

        only_pool_tool: @current_community.only_pool_tool,
        locale: I18n.locale,
        days: days,
        months: months,
        translated_days: days.map { |day_symbol| t("datepicker.days.#{day_symbol}") },
        translated_days_short: days.map { |day_symbol| t("datepicker.days_short.#{day_symbol}") },
        translated_days_min: days.map { |day_symbol| t("datepicker.days_min.#{day_symbol}") },
        translated_months: months.map { |day_symbol| t("datepicker.months.#{day_symbol}") },
        translated_months_short: months.map { |day_symbol| t("datepicker.months_short.#{day_symbol}") },
        comp_id: @company_owner.id,
        current_user_id: @current_user.id,
        current_user_username: @current_user.username,
        current_user_email: @current_user.emails.first.address,
        is_admin: @current_user.is_company_admin_of?(@company_owner) || @current_user.has_admin_rights_in?(@current_community),
        theme: @current_user.pool_tool_color_schema,

        today: t("datepicker.today"),
        week_start: t("datepicker.week_start", default: 0),
        clear: t("datepicker.clear"),
        format: t("datepicker.format"),
        add_booking: t("pool_tool.add_booking"),
        cancel_booking: t("pool_tool.cancel_booking"),
        device_name: t("pool_tool.device_name"),
        comment: t("pool_tool.comment"),
        choose_employee_or_renter_msg: t("pool_tool.show.choose_employee_or_renter"),
        deleteConfirmation: t("pool_tool.deleteConfirmation"),
        show_legend: t("pool_tool.show.show_legend"),
        hide_legend: t("pool_tool.show.hide_legend"),
        legend: t("pool_tool.show.legend"),
        trusted_company: t("pool_tool.show.trusted_company"),
        any_company: t("pool_tool.show.any_company"),
        own_employee: t("pool_tool.show.own_employee"),
        any_employee: t("pool_tool.show.any_employee"),
        other_reason: t("pool_tool.show.other_reason"),
        only_mine: t("pool_tool.show.only_mine"),
        no_devices_borrowed: t("pool_tool.show.no_devices_borrowed"),
        overdue: t("pool_tool.show.overdue"),
        return_on: t("pool_tool.show.return_on"),
        return_now: t("pool_tool.show.return_now"),
        utilization_header: t("pool_tool.load_popover.utilization_header"),
        utilization_desc_1: t("pool_tool.load_popover.utilization_desc_1"),
        utilization_desc_2: t("pool_tool.load_popover.utilization_desc_2"),
        utilization_text_outOf: t("pool_tool.load_popover.utilization_text_outOf"),
        utilization_text_days: t("pool_tool.load_popover.utilization_text_days"),
        utilization_start_date: t("pool_tool.load_popover.utilization_start_date"),
        availability_desc_header_trusted: t("pool_tool.load_popover.availability_desc_header_trusted"),
        availability_desc_header_intern: t("pool_tool.load_popover.availability_desc_header_intern"),
        availability_desc_header_all: t("pool_tool.load_popover.availability_desc_header_all"),
        availability_desc_text_trusted: t("pool_tool.load_popover.availability_desc_text_trusted"),
        availability_desc_text_intern: t("pool_tool.load_popover.availability_desc_text_intern"),
        availability_desc_text_all: t("pool_tool.load_popover.availability_desc_text_all"),

        pool_tool_preferences: {
          pooltool_user_has_to_give_back_device: @current_user.has_to_give_back_device?(@current_community),
          pool_tool_modify_past: @current_user.is_allowed_to_book_in_past?
        }
      })
    end
end
