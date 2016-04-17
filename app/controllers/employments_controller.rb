class EmploymentsController < ApplicationController
  # Add a new employment to the company (current_user)

  before_filter :ensure_is_authorized_to_change
  before_filter :ensure_user_plan_limit_not_reached, :only => :create

  def create
    if Employment.add_employee_to_company(@employee, @company)
      #flash[:notice] = "Successfully added employee to company!"
      respond_to do |format|
        format.html { redirect_to :back }
        format.js { render :partial => "people/employ_button", :locals => { :person => @employee, :company => @company } }
      end
    else
      #flash[:error] = "An error occured. Was unable to add employee to company!"
    end
  end

  def destroy
    if Employment.remove_employee_from_company(@employee, @company)
      #flash[:notice] = "Successfully removed employee from company!"
      respond_to do |format|
        format.html { redirect_to :back }
        format.js { render :partial => "people/employ_button", :locals => { :person => @employee, :company => @company } }
      end
    else
    end
  end


  private

    def ensure_is_authorized_to_change
      @employee = Person.find(params[:person_id])
      @company = @employee.company
      PersonViewUtils.ensure_person_belongs_to_community!(@employee, @current_community)

      unless current_user?(@company) || @company.is_admin_of?(@current_community)
        redirect_to root and renturn
      end
    end

    def ensure_user_plan_limit_not_reached
      if current_user?(@company)
        userplanservice = UserPlanService::Api.new
        @max_company_employees = userplanservice.get_plan_feature_level(@company, :company_employees)[:value]
        companyEmployeesCount = Employment.where(:company_id => @company.id, :active => true).count

        if companyEmployeesCount >= @max_company_employees
          respond_to do |format|
            format.html { redirect_to :back }
            format.js { render :partial => "people/max_employees_reached" }
          end
        end
      end
    end
end
