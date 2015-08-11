class EmploymentsController < ApplicationController
  # Add a new employment to the company (current_user)
  def create
    @employee = Person.find(params[:person_id])
    PersonViewUtils.ensure_person_belongs_to_community!(@employee, @current_community)

    if Employment.add_employee_to_company(@employee, @current_user)
      #flash[:notice] = "Successfully added employee to company!"
      respond_to do |format|
        format.html { redirect_to :back }
        format.js { render :partial => "people/employ_button", :locals => { :person => @employee } }
      end
    else
      #flash[:error] = "An error occured. Was unable to add employee to company!"
    end
  end

  def destroy
    @company = Person.find(params[:id])
    PersonViewUtils.ensure_person_belongs_to_community!(@company, @current_community)

    @employee = Person.find(params[:person_id])
    PersonViewUtils.ensure_person_belongs_to_community!(@employee, @current_community)

    if Employment.remove_employee_from_company(@employee, @company)
      #flash[:notice] = "Successfully removed employee from company!"
      respond_to do |format|
        format.html { redirect_to :back }
        format.js { render :partial => "people/employ_button", :locals => { :person => @employee } }
      end
    else
    end
  end
end
