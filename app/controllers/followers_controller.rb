class FollowersController < ApplicationController

  before_filter do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_view_this_content")
  end

  before_filter :check_person
  before_filter :ensure_user_plan_limit_not_reached, :only => :create

  def create
    @create_relationship = true

    # Company can't follow or trust Employee
    if @person.is_employee? && @current_user.is_organization
      flash['error'] = "Company can't follow or trust employee"
      redirect_to root_path and return
    end

    # wah: If this is a trusted relationship (company - company) then ...
    if @person.is_organization && @current_user.is_organization
      # Send Rentog message  (community, recipient, sender, message)
      Conversation.manuallyCreateConversation(@current_community, @person, @current_user, t('people.trust_button.message_to_trusted_company',:name => @person.full_name, :email => @person.emails.first.address, :profile => person_url(@current_user)))
    end

    @person.followers << @current_user

    respond_after_follow_request
  end

  def destroy
    @destroy_relationship = true

    @person.followers.delete(@current_user)

    # wah: If this is a trusted relationship (company - company) then ...
    if @person.is_organization && @current_user.is_organization
      # Send Rentog message  (community, recipient, sender, message)
      Conversation.manuallyCreateConversation(@current_community, @person, @current_user, t('people.trust_button.message_to_untrusted_company',:name => @person.full_name, :email => @person.emails.first.address, :profile => person_url(@current_user)))
    end


    respond_after_follow_request
  end



  private

    def check_person
      @person = Person.find(params[:person_id] || params[:id])
      PersonViewUtils.ensure_person_belongs_to_community!(@person, @current_community)
    end

    # each company can have n (=limit) followed companies and n followers
    # if any of the two involved companies reach the limit following is not possible
    def ensure_user_plan_limit_not_reached
      userplanservice = UserPlanService::Api.new
      @current_user_max_trusted_users = userplanservice.get_plan_feature_level(@current_user, :company_trusted_users)[:value]
      @other_company_max_trusted_users = userplanservice.get_plan_feature_level(@person, :company_trusted_users)[:value]
      current_user_followed_count = @current_user.followed_people.count
      other_company_followers_count = @person.followers.count

      # current user has reached followed limit
      if current_user_followed_count >= @current_user_max_trusted_users
        @max_followed_reached = true
        respond_to do |format|
          format.html { redirect_to :back }
          format.js { render :partial => "people/max_followers_reached" }
        end
        return
      end

      # other company has reached followers limit
      if other_company_followers_count >= @other_company_max_trusted_users
        @max_follower_reached = true
        respond_to do |format|
          format.html { redirect_to :back }
          format.js { render :partial => "people/max_followers_reached" }
        end
      end
      return
    end


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

