class PoolToolController < ApplicationController
  # Filters
  before_filter :ensure_is_authorized_to_view, :only => [ :show ]

  def show
    # Get data from database
    listings_data = Transaction.joins(:listing, :booking, :starter).select("listings.title as title, listings.privacy as privacy, bookings.start_on as start_on, bookings.end_on as end_on, bookings.created_at as created_at, transactions.current_state, people.organization_name as renting_organization").where("listings.author_id" => @current_user, "transactions.community_id" => @current_community)

    # Variables which should be send to JavaScript
    days =    [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
    months =  [:january, :february, :march, :april, :may, :june, :july, :august, :september, :october, :november, :december]

    gon.push({
      listings_data: listings_data,
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
    return if @current_user && @current_user.is_organization && @current_user.organization_name == params['person_id'].upcase

    # Rentog Admin is authorized
    return if @current_user && @current_user.has_admin_rights_in?(@current_community)

    # Otherwise return to home page
    flash[:error] = t("pool_tool.you_have_to_be_company_admin")
    redirect_to root_path and return
  end
end
