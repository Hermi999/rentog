class PoolToolController < ApplicationController
  # Filters
  before_filter :ensure_is_authorized_to_view, :only => [ :show ]

  def show
    # @person is the person which owns the profile
    @person = Person.find(params[:person_id] || params[:id])

    # Get transactions (joined with listings and bookings) from database, ordered by listings.id
    transactions = Transaction.joins(:listing, :booking, :starter).select("listings.id as listing_id, listings.title as title, listings.privacy as privacy, bookings.start_on as start_on, bookings.end_on as end_on, bookings.created_at as created_at, transactions.current_state, people.organization_name as renting_organization").where("listings.author_id" => @current_user, "transactions.community_id" => @current_community).order("listings.id asc")
    # Convert ActiveRecord Relation into array of hashes
    transaction_array = transactions.as_json

    # Go through each transaction and assign a color. If the listing isn't the
    # same as in the previous transaction, then change the color. Otherwise use
    # the same color as previously. This is possible, because the transactions
    # are ordered by id.
    prev_listing_id = 0, counter = -1
    listing_background_colors = ["#001f3f", "#FF851B", "#FF4136", "#0074D9", "#85144b", "#39CCCC", "#F012BE", "#3D9970", "#B10DC9", "#2ECC40", "#AAAAAA", "#01FF70", "#DDDDDD"]

    transaction_array.map! do |transaction|
      if prev_listing_id != transaction['listing_id']
        counter = counter + 1
      end
      transaction['color'] = listing_background_colors[counter]
      prev_listing_id = transaction['listing_id']

      # At each iteration the element in the original collection is replaced
      # by the element returned by the block
      transaction
    end


    # Variables which should be send to JavaScript
    days =    [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
    months =  [:january, :february, :march, :april, :may, :june, :july, :august, :september, :october, :november, :december]

    gon.push({
      transactions: transaction_array,
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
