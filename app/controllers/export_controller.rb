class ExportController < ApplicationController


  def index
    # Variables which should be send to JavaScript
    days =    [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
    months =  [:january, :february, :march, :april, :may, :june, :july, :august, :september, :october, :november, :december]
    gon.push({
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
    })
  end

  def show
    file_name = "export_#{@current_user.username}_#{rand(1..100000)}.xlsx"
    path_to_file = "#{Rails.root}/public/system/exportfiles/" + file_name

    start_date = Maybe(params[:start_on]).to_date.or_else(nil)
    end_date   = Maybe(params[:end_on]).to_date.or_else(nil)
    year       = Maybe(params[:year]).or_else(nil)

    if !start_date && !end_date
      if year
        start_date = ("01.01." + year).to_date
        end_date   = ("31.12." + year).to_date
      else
        start_date = ("01.01." + (Date.today.year-1).to_s).to_date
        end_date   = ("31.12." + Date.today.year.to_s).to_date
      end
    end

    # if domain supervisor, then get all the pool in the domain
    companies =
      if @relation == :domain_supervisor
        @current_user.get_companies_with_same_domain
      else
        [@current_user]
      end

    @ex = ExportService.new(companies, path_to_file, start_date, end_date)

    send_file(path_to_file, filename: file_name, type: "application/vnd.ms-excel")
  end
end
