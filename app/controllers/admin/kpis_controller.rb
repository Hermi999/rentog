class Admin::KpisController < ApplicationController

  before_filter :ensure_is_admin

  def index
    kpis = KpiService.new

    # last 15 weeks
    @kpis_weeks = kpis.get_kpis_for_chart(7, 15)

    # last 12 months
    @kpis_months = kpis.get_kpis_for_chart(30, 12)

  end

  def manually_send_kpi_to_admins
  	kpi = KpiService.new
	kpis = kpi.get_kpis_values_with_growth(7, 4)
	kpis2 = kpi.get_kpis_values_with_growth(30, 4)

	MailCarrier.deliver_now(AdminMailer.send_kpis_to_admins(kpis, kpis2, @current_community))

	redirect_to :back
  end

end
