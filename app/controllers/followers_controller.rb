class FollowersController < ApplicationController

  before_filter do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_view_this_content")
  end

  def create
    @person = Person.find(params[:person_id] || params[:id])
    PersonViewUtils.ensure_person_belongs_to_community!(@person, @current_community)

    # Company can't follow or trust Employee
    if !@person.is_organization && @current_user.is_organization
      flash['error'] = "Company can't follow or trust employee"
      redirect_to root_path and return
    end

    @person.followers << @current_user

    respond_after_follow_request
  end

  def destroy
    @person = Person.find(params[:person_id] || params[:id])
    PersonViewUtils.ensure_person_belongs_to_community!(@person, @current_community)

    @person.followers.delete(@current_user)

    respond_after_follow_request
  end



  private

    def respond_after_follow_request
      respond_to do |format|
        format.html { redirect_to :back }
        # if person is company and logged in user is a company, then render trust button, otherwise the follow_button
        if @person.is_organization && @current_user.is_organization
          format.js { render :partial => "people/trust_button", :locals => { :person => @person } }
        else
          format.js { render :partial => "people/follow_button", :locals => { :person => @person } }
        end
      end
    end

end

