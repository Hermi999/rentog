class LandingPageController < ApplicationController
  def index
    if @current_user
      if @current_user.is_organization
        redirect_to person_poolTool_path(:person_id => @current_user.username) and return
      else
        redirect_to person_poolTool_path(:person_id => @current_user.company.username) and return
      end
    end
    @landing_page = true
  end
end
