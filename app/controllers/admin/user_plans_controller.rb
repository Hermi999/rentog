class Admin::UserPlansController < ApplicationController

  before_filter :ensure_is_admin

  # Redirect to external plan service. Nothing else.
  def index
    @selected_tribe_navi_tab = "admin"
    @selected_left_navi_link = "manage_user_plans"

    @all_companies = Person.where(:is_organization => true)
    @user_plan_service = UserPlanService::Api.new
  end

  def update
    userplanservice = UserPlanService::Api.new

    if params[:feature] == "overall_user_plan"
      result = userplanservice.set_plan_and_feature_plan_levels(Person.find(params["id"]), UserPlanService::DataTypes::LEVELS.key(params["value"].to_sym))
    else
      result = userplanservice.set_feature_plan_level(Person.find(params["id"]), params["feature"].to_sym, UserPlanService::DataTypes::LEVELS.key(params["value"].to_sym))
    end

    if result
      respond_to do |format|
        format.json { render :json => {status: "success"} }
      end
    else
      respond_to do |format|
        format.json { render :json => {status: "failure"} }
      end
    end
  end

end
