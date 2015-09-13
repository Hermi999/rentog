class PoolToolController < ApplicationController
  # Filters
  before_filter :ensure_is_authorized_to_view, :only => [ :show ]
  before_filter :ensure_is_authorized_to_change, :only => [:create]

  def show
    # @person is the person which owns the company
    @person = Person.find(params[:person_id] || params[:id])

    # Get transactions (joined with listings and bookings) from database, ordered by listings.id
    transactions = Transaction.joins(:listing, :booking, :starter).select("listings.id as listing_id, listings.title as title, listings.availability as availability, bookings.start_on as start_on, bookings.end_on as end_on, bookings.created_at as created_at, transactions.current_state, people.username as renting_entity_username, people.organization_name as renting_entity_organame, people.id as person_id").where("listings.author_id" => @person, "transactions.community_id" => @current_community).order("listings.id asc")
    # Convert ActiveRecord Relation into array of hashes
    transaction_array = transactions.as_json

    # Get all open Listings of the current user
    @open_listings = Listing.currently_open.where("listings.author_id" => @person)

    # Only use certain fields in JS
    open_listings_array = []
    @open_listings.each do |listing|
      open_listings_array << { name: listing.title, desc: listing.availability, availability: listing.availability, listing_id: listing.id }
    end
    # Convert all the transaction into a jquery-Gantt readable source.
    # wah: This might be shifted to the client (javascript) in future, since
    # it would reduce load on the server
    devices = []
    act_transaction = {}
    prev_listing_id = 0, counter = -1

    transaction_array.each do |transaction|
      renter = get_renter_and_relation(transaction)
      renting_entity = transaction['renting_entity_username']
      renting_entity = transaction['renting_entity_organame'] if transaction['renting_entity_organame'] != ""

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
          'customClass' =>  "gantt_" + renter[:relation]
        }]
        transaction.except!('title', 'start_on', 'end_on', 'renting_entity_username', 'renting_entity_organame')

        prev_listing_id = transaction['listing_id']
        act_transaction = transaction
        devices << transaction

      else
        # Previous Listing, new transaction
        newTrans = {
          'from' => "/Date(" + transaction['start_on'].to_time.to_i.to_s + "000)/",
          'to' => "/Date(" + transaction['end_on'].to_time.to_i.to_s + "000)/",
          'label' => renting_entity,
          'customClass' => "gantt_" + renter[:relation]
        }
        devices[counter]['values'] << newTrans
      end
    end


    # Variables which should be send to JavaScript
    days =    [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
    months =  [:january, :february, :march, :april, :may, :june, :july, :august, :september, :october, :november, :december]

    gon.push({
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
      choose_employee_or_renter_msg: t("pool_tool.show.choose_employee_or_renter")
   })
  end

  def create
    redirect_to person_poolTool_path(params[:person_id]) and return
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
      flash[:error] = t("pool_tool.you_have_to_be_company_member")
      redirect_to root_path and return
    end


    def ensure_is_authorized_to_change()
      # # Company Admin is authorized
      return if @current_user && @current_user.is_organization && @current_user.username == params['person_id']

      # Rentog Admin is authorized
      return if @current_user && @current_user.has_admin_rights_in?(@current_community)

      # Otherwise return to home page
      flash[:error] = t("pool_tool.you_have_to_be_company_admin")
      redirect_to root_path and return
    end


    def get_renter_and_relation(transaction)
      # How is the relation between the company & the renter of this one listing?
        renter = Person.where(id: transaction["person_id"]).first
        if renter.is_organization
          # Company is renting listing
          if @person.follows?(renter)
            # Other company is trusted by the company
            relation = "trustedCompany"
          else
            # Other company is not trusted by the company
            relation = "anyCompany"
          end
        else
          # Any Employee is renting listing
          if renter.is_employee?(@person.id)
            # Own employee is renting listing
            relation = "ownEmployee"
          else
            # Employee of another company is renting listing
            relation = "anyEmployee"
          end
        end

        { renter: renter, relation: relation }
    end
end
