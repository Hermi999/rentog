class EmploymentsController < ApplicationController
  # Add a new employment to the company (current_user)
  def create
    if add_employee_to_company(params[:employee_id], @current_user)
      flash[:notice] = "Successfully added employee to company!"
      redirect_to root_url
    else
      flash[:error] = "An error occured. Was unable to add employee to company!"
      redirect_to root_url
    end
  end

  def destroy
    if remove_employee_from_company(params[:id])
      flash[:notice] = "Successfully removed employee from company!"
      redirect_to root_url
    else
    end
  end
end
