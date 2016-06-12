require 'benchmark'

class CompanyStatisticsController < ApplicationController

  before_filter :ensure_is_authorized_to_view

  def show
    company_ids = []
    if @relation == :domain_supervisor && params[:domain_view] == "1"
      company_ids += @current_user.get_companies_with_same_domain.map(&:id)
    else
      company_ids = @site_owner.id
    end

    statistics = StatisticsService.new(company_ids, @current_community.id)
    data = {
      averageDeviceBookingPeriod: statistics.averageDeviceBookingPeriod,
      peopleWithMostBookings: statistics.peopleWithMostBookings,
      peopleWithMostBookedDays: statistics.peopleWithMostBookedDays,
      devicesWithMostBookings: statistics.devicesWithMostBookings,
      devicesWithMostBookedDays: statistics.devicesWithMostBookedDays,
      bookingCompanyUnits: statistics.bookingCompanyUnits,
      deviceLivetime: statistics.deviceLivetime,
      userDeviceRelationship: statistics.userDeviceRelationship,
      deviceBookingDensityPerDay: statistics.deviceBookingDensityPerDay
    }

    gon.push({
      data: data,
      averageDeviceBookingPeriod_hAxis_title: t("company_statistics.averageDeviceBookingPeriod_hAxis_title"),
      averageDeviceBookingPeriod_vAxis_title: t("company_statistics.averageDeviceBookingPeriod_vAxis_title"),
      peopleWithMostBookings_hAxis_title: t("company_statistics.peopleWithMostBookings_hAxis_title"),
      peopleWithMostBookedDays_hAxis_title: t("company_statistics.peopleWithMostBookedDays_hAxis_title"),
      devicesWithMostBookings_hAxis_title: t("company_statistics.devicesWithMostBookings_hAxis_title"),
      devicesWithMostBookedDays_hAxis_title: t("company_statistics.devicesWithMostBookedDays_hAxis_title"),
      bookingCompanyUnits_hAxis_title: t("company_statistics.bookingCompanyUnits_hAxis_title"),
      bookingCompanyUnits_yAxis_title: t("company_statistics.bookingCompanyUnits_yAxis_title"),
      userDeviceRelationship_column_title: t("company_statistics.userDeviceRelationship_column_title")
    })
  end


  private

    # employees of the company can view the side, but they do not have a
    # button in the pool tool side bar for it. This way the admin can send
    # the link to his employees
    def ensure_is_authorized_to_view
      @is_member_of_company = (@relation == :company_admin_own_site || @relation == :company_employee || @relation == :rentog_admin_own_site)

      # ALLOWED
        return if @relation == :rentog_admin ||
                  @relation == :rentog_admin_own_site ||
                  @relation == :domain_supervisor ||
                  @relation == :company_admin_own_site


      # NOT ALLOWED
        # with error message
        flash[:error] = t("listing_events.you_have_to_be_company_member")
        redirect_to root
        return false
    end

end
