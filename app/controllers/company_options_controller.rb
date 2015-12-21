class CompanyOptionsController < ApplicationController
  def update
    options_hash = {}

    CompanyOption::COMPANY_OPTIONS.each do |company_option|
      options_hash[company_option] = params[:company_option][company_option] || "false"
    end

    @current_user.company_option.update_attributes(options_hash)

    redirect_to :back
  end
end
