class PoolToolController < ApplicationController
  # Filters
  before_filter :ensure_is_authorized_to_view, :only => [ :show ]

  def show
    # @person is the person which owns the profile
    @person = Person.find(params[:person_id] || params[:id])

    # Get transactions (joined with listings and bookings) from database, ordered by listings.id
    transactions = Transaction.joins(:listing, :booking, :starter).select("listings.id as listing_id, listings.title as title, listings.availability as availability, bookings.start_on as start_on, bookings.end_on as end_on, bookings.created_at as created_at, transactions.current_state, people.organization_name as renting_organization").where("listings.author_id" => @current_user, "transactions.community_id" => @current_community).order("listings.id asc")
    # Convert ActiveRecord Relation into array of hashes
    transaction_array = transactions.as_json

    # Get all open Listings of the current user
    open_listings = Listing.currently_open.where("listings.author_id" => @current_user).select('listings.title')

    open_listings_array = []
    open_listings.each do |listing|
      open_listings_array << listing.title
    end

    # Convert all the transaction into a jquery-Gantt readable source.
    # wah: This might be shifted to the client (javascript) in future, since
    # it would reduce load on the server
    listing_background_colors = ["ganttRed", "ganttGreen", "ganttBlue", "ganttOrange"]
    devices = []
    act_transaction = {}
    prev_listing_id = 0, counter = -1

    transaction_array.each do |transaction|
      if prev_listing_id != transaction['listing_id']
        counter = counter + 1
        transaction['name'] = transaction['title']
        transaction['customClass'] = listing_background_colors[counter]
        transaction['values'] = [{
          'from' => "/Date(" + transaction['start_on'].to_time.to_i.to_s + "000)/",
          'to' => "/Date(" + transaction['end_on'].to_time.to_i.to_s + "000)/",
          'label' => transaction['renting_organization']
        }]
        transaction.except!('title', 'start_on', 'end_on', 'renting_organization')

        prev_listing_id = transaction['listing_id']
        act_transaction = transaction
        devices << transaction
      else
        newTrans = {
          'from' => "/Date(" + transaction['start_on'].to_time.to_i.to_s + "000)/",
          'to' => "/Date(" + transaction['end_on'].to_time.to_i.to_s + "000)/",
          'label' => transaction['renting_organization']
        }
        devices[counter]['values'] << newTrans
      end
    end


    # Variables which should be send to JavaScript
    days =    [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
    months =  [:january, :february, :march, :april, :may, :june, :july, :august, :september, :october, :november, :december]

    gon.push({
      transactions: transaction_array,
      devices: devices,
      open_listings: open_listings_array,
      locale: I18n.locale,
      days: days,
      months: months,
      translated_days: days.map { |day_symbol| t("datepicker.days.#{day_symbol}") },
      translated_days_short: days.map { |day_symbol| t("datepicker.days_short.#{day_symbol}") },
      translated_days_min: days.map { |day_symbol| t("datepicker.days_min.#{day_symbol}") },
      translated_months: months.map { |day_symbol| t("datepicker.months.#{day_symbol}") },
      translated_months_short: months.map { |day_symbol| t("datepicker.months_short.#{day_symbol}") },
      today: t("datepicker.today"),
      week_start: t("datepicker.week_start", default: 0),
      clear: t("datepicker.clear"),
      format: t("datepicker.format"),

      add_reservation: t("pool_tool.add_reservation"),
      cancel_reservation: t("pool_tool.cancel_reservation"),
      device_name: t("pool_tool.device_name"),
      comment: t("pool_tool.comment"),
   })
  end



  private

    def ensure_is_authorized_to_view()
      # Company Admin is authorized
      return if @current_user && @current_user.is_organization && @current_user.username == params['person_id']

      # Rentog Admin is authorized
      return if @current_user && @current_user.has_admin_rights_in?(@current_community)

      # Company employee is authorized
      return if @current_user && @current_user.is_employee?(params['person_id'])

      # Otherwise return to home page
      flash[:error] = t("pool_tool.you_have_to_be_company_admin")
      redirect_to root_path and return
    end
end
