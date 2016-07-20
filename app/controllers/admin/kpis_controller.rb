class Admin::KpisController < ApplicationController

  before_filter :ensure_is_admin

  def index
    kpis = KpiService.new

    # last 15 weeks
    @kpis_weeks = kpis.get_kpis_for_chart(7, 15)

    # last 12 months
    @kpis_months = kpis.get_kpis_for_chart(30, 12)

  end

end
