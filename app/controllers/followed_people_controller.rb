# This controller does not only handle displaying the followed people, but also
# the employees of a company, because the code is identically.

class FollowedPeopleController < ApplicationController

  def index
    @person = Person.find(params[:person_id] || params[:id])
    PersonViewUtils.ensure_person_belongs_to_community!(@person, @current_community)

    if params[:type] == "employees"
      @followed_people = @person.employees
    else
      @followed_people = @person.followed_people
    end

    respond_to do |format|
      format.js { render :partial => "people/followed_person", :collection => @followed_people, :as => :person }
    end
  end

  # Add or remove followed people from FollowersController

end

