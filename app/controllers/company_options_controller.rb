class CompanyOptionsController < ApplicationController
  def update
    options_hash = {}

    CompanyOption::COMPANY_OPTIONS.each do |company_option|
      options_hash[company_option] = (params[:company_option][company_option] || "false") == "true"
    end

    @current_user.company_option.update_attributes(options_hash)

    redirect_to person_poolTool_path(@current_user.get_company)
  end
end
