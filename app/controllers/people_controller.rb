class PeopleController < Devise::RegistrationsController
  class PersonDeleted < StandardError; end

  include PeopleHelper

  # Handle exceptions
  rescue_from Net::SMTPFatalError, :with => :error_render_method

  skip_before_filter :verify_authenticity_token, :only => [:creates]
  skip_before_filter :require_no_authentication, :only => [:new]

  before_filter :only => [ :update, :destroy ] do |controller|
    controller.ensure_authorized t("layouts.notifications.you_are_not_authorized_to_view_this_content")
  end

  before_filter :ensure_is_admin, :only => [ :activate, :deactivate ]

  skip_filter :check_confirmations_and_verifications, :only => [ :update, :destroy]
  skip_filter :cannot_access_without_joining, :only => [ :check_email_availability_and_validity, :check_company_email, :check_invitation_code ]

  # Skip auth token check as current jQuery doesn't provide it automatically
  skip_before_filter :verify_authenticity_token, :only => [:activate, :deactivate]

  helper_method :show_closed?

  def show
    # @person is the person which owns the profile
    @person = Person.find(params[:person_id] || params[:id])

    raise PersonDeleted if @person.deleted?
    PersonViewUtils.ensure_person_belongs_to_community!(@person, @current_community)

    # if person is an employee find out the organization he works for
    @organization = @person.company
    # if person is an company get all the employees
    @employees = @person.employees
    # WORKAROUND: create path for showing more than 6 employees
    @employees_path = request.original_url + '/followed_people?type=employees'


    redirect_to root and return if @current_community.private? && !@current_user
    @selected_tribe_navi_tab = "members"
    @community_membership = CommunityMembership.find_by_person_id_and_community_id_and_status(@person.id, @current_community.id, "accepted")

    # Do not show internal listings if current logged in user is not ...
    if  !@current_user ||                                          # logged in or
        !@current_user.is_employee_of?(@person.id) &&              # not an employee of the company and
        !@current_user.has_admin_rights_in?(@current_community) && # not the rentog admin and
        !current_user?(@person)                                    # not the company admin himself
      availability = ["all", "trusted"]
    end

    include_closed = @current_user == @person && params[:show_closed]
    search = {
      author_id: @person.id,
      include_closed: include_closed,
      page: 1,
      per_page: 6,
      availability: availability,    # wah new
    }

    includes = [:author, :listing_images]
    listings = ListingIndexService::API::Api.listings.search(community_id: @current_community.id, search: search, includes: includes).and_then { |res|
      Result::Success.new(
        ListingIndexViewUtils.to_struct(
        result: res,
        includes: includes,
        page: search[:page],
        per_page: search[:per_page]
      ))
    }.data

    render locals: { listings: listings }
  end

  def new
    # define javascript variables with values from backend
    gon.push({
      btn_create_company: t("people.new.create_new_account"),
      btn_create_employee: t("people.new.create_new_employee"),
      main_description: t("people.new.help_texts.main_description"),
      person_email: t("people.new.help_texts.person_email"),
      person_organization_name: t("people.new.help_texts.person_organization_name"),
      person_organization_email: t("people.new.help_texts.person_organization_email"),
      person_password1: t("people.new.help_texts.person_password1"),
      signup_employee: t("people.new.help_texts.signup_employee")
    });

    @selected_tribe_navi_tab = "members"
    @all_organizations = Person.where(:is_organization => true, :is_admin => false)

    redirect_to root if logged_in?
    session[:invitation_code] = params[:code] if params[:code]

    @person = if params[:person] then
      Person.new(params[:person].slice(:given_name, :family_name, :email, :username))
    else
      Person.new()
    end

    @container_class = params[:private_community] ? "container_12" : "container_24"
    @grid_class = params[:private_community] ? "grid_6 prefix_3 suffix_3" : "grid_10 prefix_7 suffix_7"
  end

  def create
    @current_community ? domain = @current_community.full_url : domain = "#{request.protocol}#{request.host_with_port}"
    error_redirect_path = domain + sign_up_path

    # Honey pot for spammerbots
    if params[:person][:input_again].present?
      flash[:error] = t("layouts.notifications.registration_considered_spam")
      ApplicationHelper.send_error_notification("Registration Honey Pot is hit.", "Honey pot")
      redirect_to error_redirect_path and return
    end

    # Create username
    if !params[:person][:username].present?
      if params[:person][:organization_name] == ""
        #params[:person][:username] = "em_" + params[:person][:organization_name2].truncate(4, omission: '') + "_" + (params[:person][:given_name]).truncate(3, omission: '') + "_" + (params[:person][:family_name]).truncate(3, omission: '') + "_" + rand(0..9999).to_s
        params[:person][:username] = "em_" + params[:person][:organization_email].truncate(4, omission: '') + "_" + (params[:person][:given_name]).truncate(3, omission: '') + "_" + (params[:person][:family_name]).truncate(3, omission: '') + "_" + rand(0..9999).to_s
      else
        params[:person][:username] = "co_" + params[:person][:organization_name].truncate(11, omission: '') + "_" + rand(0..9999).to_s
      end
    end

    # How does the user wants to signup (if not specified or data is missing, then show an error
    if(signup_as = params[:person][:signup_as]).nil? ||
      params[:person][:signup_as] == "organization" && (params[:person][:organization_name]).nil? ||
      #params[:person][:signup_as] == "employee" && (params[:person][:organization_name2]).nil?
      params[:person][:signup_as] == "employee" && (params[:person][:organization_email]).nil?
        flash[:error] = t("people.new.invalid_form_data")
        redirect_to error_redirect_path and return
    end

    # Check invitation code
    if @current_community && @current_community.join_with_invite_only? || params[:invitation_code]
      unless Invitation.code_usable?(params[:invitation_code], @current_community)
        # abort user creation if invitation is not usable.
        # (This actually should not happen since the code is checked with javascript)
        session[:invitation_code] = nil # reset code from session if there was issues so that's not used again
        ApplicationHelper.send_error_notification("Invitation code check did not prevent submiting form, but was detected in the controller", "Invitation code error")

        # TODO: if this ever happens, should change the message to something else than "unknown error"
        flash[:error] = t("layouts.notifications.unknown_error")
        redirect_to error_redirect_path and return
      else
        invitation = Invitation.find_by_code(params[:invitation_code].upcase)
      end
    end

    # Check that email is not taken
    unless Email.email_available?(params[:person][:email])
      flash[:error] = t("people.new.email_is_in_use")
      redirect_to error_redirect_path and return
    end

    # Check that the email is allowed for current community
    if @current_community && ! @current_community.email_allowed?(params[:person][:email])
      flash[:error] = t("people.new.email_not_allowed")
      redirect_to error_redirect_path and return
    end

    # If an organization should be created
    if signup_as == "organization"
      # Check that organization is not taken if a new organization is registered
      unless Person.organization_name_available?(params[:person][:organization_name])
        flash[:error] = t("people.new.organization_is_in_use")
        redirect_to error_redirect_path and return
      end

    # If an employee should be created
    elsif signup_as == "employee"
      # Check that the given organization is available if a new employee should be registered
      #if Person.organization_name_available?(params[:person][:organization_name2])
      if !Person.organization_email_available?(params[:person][:organization_email])
        flash[:error] = t("people.new.organization_doesnt_exists")
        redirect_to error_redirect_path and return
      end
    end

    @person, email = new_person(params, @current_community)

    # Make person a member of the current community
    if @current_community
      membership = CommunityMembership.new(:person => @person, :community => @current_community, :consent => @current_community.consent)
      membership.status = "pending_email_confirmation"
      membership.invitation = invitation if invitation.present?
      # If the community doesn't have any members, make the first one an admin
      if @current_community.members.count == 0
        membership.admin = true
      end
      membership.save!
      session[:invitation_code] = nil
    end

    session[:person_id] = @person.id

    # If invite was used, reduce usages left
    invitation.use_once! if invitation.present?

    Delayed::Job.enqueue(CommunityJoinedJob.new(@person.id, @current_community.id)) if @current_community

    # send email confirmation
    # (unless disabled for testing environment)
    if APP_CONFIG.skip_email_confirmation
      email.confirm!

      redirect_to root
    else
      Email.send_confirmation(email, @current_community)

      flash[:notice] = t("layouts.notifications.account_creation_succesful_you_still_need_to_confirm_your_email")
      redirect_to :controller => "sessions", :action => "confirmation_pending", :origin => "email_confirmation"
    end

    # If employee, send message & email to company for confirming new employee
    if signup_as == "employee"
      Conversation.manuallyCreateConversation(@current_community, @person.company, @person, t('people.new.message_to_company_owner',:name => @person.full_name, :email => @person.emails.first.address, :profile => person_url(@person.company)))
      PersonMailer.new_employee_notification(@person, @person.company, @current_community, @person.emails.first.address)
    end
  end

  def build_devise_resource_from_person(person)
    params["person"].delete(:terms) #remove terms part which confuses Devise

    # This part is copied from Devise's regstration_controller#create
    build_resource
    person = resource

    person
  end

  def create_facebook_based
    username = UserService::API::Users.username_from_fb_data(
      username: session["devise.facebook_data"]["username"],
      given_name: session["devise.facebook_data"]["given_name"],
      family_name: session["devise.facebook_data"]["family_name"])

    person_hash = {
      :username => username,
      :given_name => session["devise.facebook_data"]["given_name"],
      :family_name => session["devise.facebook_data"]["family_name"],
      :facebook_id => session["devise.facebook_data"]["id"],
      :locale => I18n.locale,
      :test_group_number => 1 + rand(4),
      :password => Devise.friendly_token[0,20]
    }
    @person = Person.create!(person_hash)
    # We trust that Facebook has already confirmed these and save the user few clicks
    Email.create!(:address => session["devise.facebook_data"]["email"], :send_notifications => true, :person => @person, :confirmed_at => Time.now)

    @person.set_default_preferences

    @person.store_picture_from_facebook

    session[:person_id] = @person.id
    sign_in(resource_name, @person)
    flash[:notice] = t("layouts.notifications.login_successful", :person_name => view_context.link_to(@person.given_name_or_username, person_path(@person))).html_safe

    # We can create a membership for the user if there are no restrictions
    # - not an Invite only community
    # - has same terms of use
    # - if there's email limitation the user has suitable email in FB
    # But as this is bit complicated, for now
    # we don't create the community membership yet, because we can use the already existing checks for invitations and email types.
    session[:fb_join] = "pending_analytics"
    redirect_to :controller => :community_memberships, :action => :new
  end

  def update
    # If setting new location, delete old one first
    if params[:person] && params[:person][:location] && (params[:person][:location][:address].empty? || params[:person][:street_address].blank?)
      params[:person].delete("location")
      if @person.location
        @person.location.delete
      end
    end

    #Check that people don't exploit changing email to be confirmed to join an email restricted community
    if params["request_new_email_confirmation"] && @current_community && ! @current_community.email_allowed?(params[:person][:email])
      flash[:error] = t("people.new.email_not_allowed")
      redirect_to :back and return
    end

    @person.set_emails_that_receive_notifications(params[:person][:send_notifications])

    begin
      person_params = params[:person].slice(
        :given_name,
        :family_name,
        :street_address,
        :phone_number,
        :image,
        :description,
        :location,
        :password,
        :password2,
        :send_notifications,
        :email_attributes,
        :min_days_between_community_updates,
        :preferences,
      )

      if @person.update_attributes(person_params)
        if params[:person][:password]
          #if password changed Devise needs a new sign in.
          sign_in @person, :bypass => true
        end

        if params[:person][:email_attributes] && params[:person][:email_attributes][:address]
          # A new email was added, send confirmation email to the latest address
          Email.send_confirmation(@person.emails.last, @current_community)
        end

        flash[:notice] = t("layouts.notifications.person_updated_successfully")

        # Send new confirmation email, if was changing for that
        if params["request_new_email_confirmation"]
            @person.send_confirmation_instructions(request.host_with_port, @current_community)
            flash[:notice] = t("layouts.notifications.email_confirmation_sent_to_new_address")
        end
      else
        flash[:error] = t("layouts.notifications.#{@person.errors.first}")
      end
    rescue RestClient::RequestFailed => e
      flash[:error] = t("layouts.notifications.update_error")
    end

    redirect_to :back
  end

  def destroy
    has_unfinished = TransactionService::Transaction.has_unfinished_transactions(@current_user.id)
    return redirect_to root if has_unfinished

    communities = @current_user.community_memberships.map(&:community_id)

    # Do all delete operations in transaction. Rollback if any of them fails
    ActiveRecord::Base.transaction do
      UserService::API::Users.delete_user(@current_user.id)
      MarketplaceService::Listing::Command.delete_listings(@current_user.id)

      communities.each { |community_id|
        PaypalService::API::Api.accounts.delete(community_id: @current_community.id, person_id: @current_user.id)
      }
    end

    sign_out @current_user
    report_analytics_event(['user', "deleted", "by user"]);
    flash[:warning] = t("layouts.notifications.account_deleted")
    redirect_to root
  end

  def check_username_availability
    respond_to do |format|
      format.json { render :json => Person.username_available?(params[:person][:username]) }
    end
  end

  def check_organization_name_availability
    respond_to do |format|
      format.json { render :json => Person.organization_name_available?(params[:person][:organization_name]) }
    end
  end

  #This checks also that email is allowed for this community
  def check_email_availability_and_validity
    # this can be asked from community_membership page or new user page
    email = params[:person] && params[:person][:email] ? params[:person][:email] : params[:community_membership][:email]

    available = true

    #first check if the community allows this email
    if @current_community.allowed_emails.present?
      available = @current_community.email_allowed?(email)
    end

    if available
      # Then check if it's already in use
      email_availability(email, true)
    else #respond false
      respond_to do |format|
        format.json { render :json => available }
      end
    end
  end

  def check_company_email
    email = params[:person][:organization_email]
    company_email_availability(email)
  end

  # this checks that email is not already in use for anyone (including current user)
  def check_email_availability
    email = params[:person] && params[:person][:email_attributes] && params[:person][:email_attributes][:address]
    email_availability(email, false)
  end

  def check_invitation_code
    respond_to do |format|
      format.json { render :json => Invitation.code_usable?(params[:invitation_code], @current_community) }
    end
  end

  def show_closed?
    params[:closed] && params[:closed].eql?("true")
  end

  def check_captcha
    if verify_recaptcha_unless_already_accepted
      render :json => "success" and return
    else
      render :json => "failed" and return
    end
  end

  # Showed when somebody tries to view a profile of
  # a person that is not a member of that community
  def not_member
  end

  def activate
    change_active_status("activated")
  end

  def deactivate
    change_active_status("deactivated")
  end

  private

  # Create a new person by params and current community
  def new_person(params, current_community)
    person = Person.new
    if APP_CONFIG.use_recaptcha && current_community && current_community.use_captcha && !verify_recaptcha_unless_already_accepted(:model => person, :message => t('people.new.captcha_incorrect'))

      # This should not actually ever happen if all the checks work at Sharetribe's end.
      # Anyway if Captha responses with error, show message to user
      # Also notify admins that this kind of error happened.
      # TODO: if this ever happens, should change the message to something else than "unknown error"
      flash[:error] = t("layouts.notifications.unknown_error")
      ApplicationHelper.send_error_notification("New user Sign up failed because Captha check failed, when it shouldn't.", "Captcha error")
      redirect_to error_redirect_path and return false
    end

    params[:person][:locale] =  params[:locale] || APP_CONFIG.default_locale
    params[:person][:test_group_number] = 1 + rand(4)

    email = Email.new(:person => person, :address => params[:person][:email].downcase, :send_notifications => true)
    params["person"].delete(:email)

    person = build_devise_resource_from_person(person)

    person.emails << email

    person.inherit_settings_from(current_community)

    # Change the user type according to the params
    if params[:person][:signup_as] == "organization"
      person.is_organization = true
    elsif params[:person][:signup_as] == "employee"
      person.is_organization = false
      # Also set up a relationship to the given company per email
      #person.company = Person.find_by_organization_name(params[:person][:organization_name2])
      person.company = Person.find_by_email(params[:person][:organization_email])
    end

    if person.save!
      sign_in(resource_name, resource)
    end

    person.set_default_preferences

    [person, email]
  end

  def email_availability(email, own_email_allowed)
    available = own_email_allowed ? Email.email_available_for_user?(@current_user, email) : Email.email_available?(email)

    respond_to do |format|
      format.json { render :json => available }
    end
  end

  def company_email_availability(email)
    available = Email.company_email_available?(email)

    respond_to do |format|
      format.json { render :json => available }
    end
  end

  def verify_recaptcha_unless_already_accepted(options={})
    # Check if this captcha is already accepted, because ReCAPTCHA API will return false for further queries
    if session[:last_accepted_captha] == "#{params["recaptcha_challenge_field"]}#{params["recaptcha_response_field"]}"
      return true
    else
      accepted = verify_recaptcha(options)
      if accepted
        session[:last_accepted_captha] = "#{params["recaptcha_challenge_field"]}#{params["recaptcha_response_field"]}"
      end
      return accepted
    end
  end

  def change_active_status(status)
    @person = Person.find(params[:id])
    #@person.update_attribute(:active, 0)
    @person.update_attribute(:active, (status.eql?("activated") ? true : false))
    @person.listings.update_all(:open => false) if status.eql?("deactivated")
    flash[:notice] = t("layouts.notifications.person_#{status}")
    respond_to do |format|
      format.html {
        redirect_to @person
      }
      format.js {
        render :layout => false
      }
    end
  end

  # Exception handler
  def error_render_method
    flash[:error] = "Email address is not verified by Amazon SES. This should only occur during testing."
    redirect_to request.original_url
    return
  end
end
