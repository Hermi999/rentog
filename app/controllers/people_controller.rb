class PeopleController < Devise::RegistrationsController
  class PersonDeleted < StandardError; end

  skip_before_filter :verify_authenticity_token, :only => [:creates]
  skip_before_filter :require_no_authentication, :only => [:new]

  before_filter :only => [ :update, :destroy ] do |controller|
    controller.ensure_authorized t("layouts.notifications.you_are_not_authorized_to_view_this_content")
  end

  before_filter :only => [:show] do
    render nothing: true, status: 404 unless @site_owner
  end

  before_filter :ensure_is_admin, :only => [ :activate, :deactivate ]

  skip_filter :check_confirmations_and_verifications, :only => [ :update, :destroy]
  skip_filter :cannot_access_without_joining, :only => [ :check_email_availability_and_validity, :check_company_email, :check_invitation_code ]

  # Skip auth token check as current jQuery doesn't provide it automatically
  skip_before_filter :verify_authenticity_token, :only => [:activate, :deactivate]

  helper_method :show_closed?

  def show
    raise PersonDeleted if @site_owner.deleted?
    PersonViewUtils.ensure_person_belongs_to_community!(@site_owner, @current_community)

    @is_member_of_company = (@relation == :company_admin_own_site || @relation == :company_employee || @relation == :rentog_admin_own_site)

    # WORKAROUND: create path for showing more than 6 employees
    @employees_path = request.original_url + '/followed_people?type=employees'

    redirect_to root and return if @current_community.private? && !@current_user
    @selected_tribe_navi_tab = "members"
    @community_membership = CommunityMembership.find_by_person_id_and_community_id_and_status(@site_owner.id, @current_community.id, "accepted")


    # Restrict (depending on viewer):
    #   - which listings are viewed on profile page
    if @relation == :logged_out
      availability = ["all", nil, ""]

    elsif @relation == :company_admin_own_site ||
          @relation == :company_employee ||
          @relation == :rentog_admin
      availability = ["all", "trusted", "intern", nil, ""]

    elsif @relation == :full_trusted_company_admin ||
          @relation == :trusted_company_admin ||
          @relation == :full_trusted_company_employee ||
          @relation == :trusted_company_employee
      availability = ["all", "trusted", nil, ""]

    else
      availability = ["all", nil, ""]
    end


    include_closed = @current_user == @site_owner && params[:show_closed]
    search = {
      author_id: @site_owner.id,
      include_closed: include_closed,
      page: 1,
      per_page: 1000,                # wah 'show all listings' not working at the moment
      availability: availability,    # wah new
    }

    includes = [:author, :listing_images]
    raise_errors = Rails.env.development?

    search_res =
      ListingIndexService::API::Api
      .listings
      .search(
        community_id: @current_community.id,
        search: search,
        engine: search_engine,
        raise_errors: raise_errors,
        includes: includes
      )

    # wah: split listings into Renting, Selling and Ad
    renting_listings_arr = []
    selling_listings_arr = []
    ad_listings_arr = []
    other_listings_arr = []
    search_res.data[:listings].each do |listing|
      # Selling or ad listing or other type
      if listing[:availability].nil?
        type = Listing.get_listing_type(listing)
        if type == "sell"
          selling_listings_arr << listing
        elsif type == "ad"
          ad_listings_arr << listing
        else
          other_listings_arr << listing
        end

      # Renting listing
      else
        if listing != []

          renting_listings_arr << listing
        end
      end
    end

    # wah: create new Result:Success object
    renting_temp = Result::Success.new({count: renting_listings_arr.count, listings: renting_listings_arr})
    selling_temp = Result::Success.new({count: selling_listings_arr.count, listings: selling_listings_arr})
    ad_temp = Result::Success.new({count: ad_listings_arr.count, listings: ad_listings_arr})
    other_temp = Result::Success.new({count: other_listings_arr.count, listings: other_listings_arr})


    # wah: prepare listings for view
    renting_listings = renting_temp.and_then { |res|
      Result::Success.new(
        ListingIndexViewUtils.to_struct(
        result: res,
        includes: includes,
        page: search[:page],
        per_page: search[:per_page]
      ))
    }.data
    selling_listings = selling_temp.and_then { |res|
      Result::Success.new(
        ListingIndexViewUtils.to_struct(
        result: res,
        includes: includes,
        page: search[:page],
        per_page: search[:per_page]
      ))
    }.data
    ad_listings = ad_temp.and_then { |res|
      Result::Success.new(
        ListingIndexViewUtils.to_struct(
        result: res,
        includes: includes,
        page: search[:page],
        per_page: search[:per_page]
      ))
    }.data
    other_listings = other_temp.and_then { |res|
      Result::Success.new(
        ListingIndexViewUtils.to_struct(
        result: res,
        includes: includes,
        page: search[:page],
        per_page: search[:per_page]
      ))
    }.data


    followed_people = followed_people_in_community(@site_owner, @current_community)
    followers = @site_owner.followers
    received_testimonials = TestimonialViewUtils.received_testimonials_in_community(@site_owner, @current_community)
    received_positive_testimonials = TestimonialViewUtils.received_positive_testimonials_in_community(@site_owner, @current_community)
    feedback_positive_percentage = @site_owner.feedback_positive_percentage_in_community(@current_community)

    render locals: { renting_listings: renting_listings,
                     selling_listings: selling_listings,
                     ad_listings: ad_listings,
                     other_listings: other_listings,
                     followed_people: followed_people,
                     followers: followers,
                     company_member: (@relation == :company_admin_own_site || @relation == :company_employee || @current_user == @site_owner),
                     received_testimonials: received_testimonials,
                     received_positive_testimonials: received_positive_testimonials,
                     feedback_positive_percentage: feedback_positive_percentage
                   }
  end


  def new
    # Check if signup link is an invitation from a company admin
    company_inviter = false
    if params[:code].present? && params[:ref].present? && params[:ref] == "email"

      if Invitation.code_usable?(params[:code], @current_community)
        invitation = Invitation.find_by_code(params[:code].upcase)
      else
        flash[:error] = "Invitation code invalid"
        redirect_to sign_up_path and return
      end

      if invitation && invitation.present?
        invited_email = invitation.email
        inviter = Person.where(id: invitation.inviter_id).first

        if invitation.target == "employee"
          company_invitation = true

          if inviter.is_organization?
            inviter_name = inviter.organization_name
          else
            inviter_name = inviter.company.organization_name
          end
        end
      end
    end

    # define javascript variables with values from backend
    gon.push({
      btn_create_company: t("people.new.create_new_account"),
      btn_create_employee: t("people.new.create_new_employee"),
      person_email: t("people.new.help_texts.person_email"),
      person_organization_name: t("people.new.help_texts.person_organization_name"),
      person_organization_email: t("people.new.help_texts.person_organization_email"),
      person_password1: t("people.new.help_texts.person_password1"),
      signup_employee: t("people.new.help_texts.signup_employee"),
      invitation: company_invitation,
      organization_name: inviter_name,
      employee_email: invited_email
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

  # Signup of a new user
  def create
    @current_community ? domain = @current_community.full_url : domain = "#{request.protocol}#{request.host_with_port}"
    error_redirect_path = domain + sign_up_path

    # Honey pot for spammerbots
    if params[:person][:input_again].present?
      flash[:error] = t("layouts.notifications.registration_considered_spam")
      ApplicationHelper.send_error_notification("Registration Honey Pot is hit.", "Honey pot")
      redirect_to error_redirect_path and return
    end

    # How does the user wants to signup (if not specified or data is missing, then show an error
    if(signup_as = params[:person][:signup_as]).nil? ||
      params[:person][:signup_as] == "organization" && (params[:person][:organization_name]).nil? ||
      params[:person][:signup_as] == "employee" && (params[:person][:organization_email]).nil?
        flash[:error] = t("people.new.invalid_form_data")
        redirect_to error_redirect_path and return
    end

    # Check invitation code
    if @current_community && @current_community.join_with_invite_only? || (params[:invitation_code])
      # Employee can only use invitation codes where the email is already stored Invitation-Model in the DB
      temp_email = params[:person][:email] if signup_as == "employee"

      unless Invitation.code_usable?(params[:invitation_code], @current_community, temp_email)
        # abort user creation if invitation is not usable.
        # (This actually should not happen since the code is checked with javascript)
        session[:invitation_code] = nil # reset code from session if there was issues so that's not used again
        ApplicationHelper.send_error_notification("Invitation code check did not prevent submiting form, but was detected in the controller", "Invitation code error")

        # TODO: if this ever happens, should change the message to something else than "unknown error"
        flash[:error] = t("layouts.notifications.unknown_error")
        redirect_to error_redirect_path and return
      else
        invitation = Invitation.find_by_code(params[:invitation_code].upcase)

        # If employee-invitation from a company admin
        inviter = Person.where(id: invitation.inviter_id).first

        if inviter.nil?
          flash[:error] = "Something went wrong with your invitation"
          redirect_to error_redirect_path and return
        end

        # If invitation is for company employee, ...
        if invitation.target == "employee"
          invited_email = invitation.email
        else
          inviter = nil
        end
      end
    end

    # Get correct email if company invited employee
    params[:person][:email] = params[:person][:email] || invited_email

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
      # If employee got an invitation, then the company is the inviter
      comp = inviter || Person.organization_email_available?(params[:person][:organization_email])
      if comp.nil?
        flash[:error] = t("people.new.organization_doesnt_exists")
        redirect_to error_redirect_path and return
      else
        # If comp.organization_name is nil, then the inviter was an employee and we take the company of the employee
        params[:person][:company_name] = comp.organization_name || comp.company.organization_name
      end
    end

    # Create username
    if !params[:person][:username].present?
      if signup_as == "employee"
        params[:person][:username] = "em_" + params[:person][:company_name].gsub(/[^0-9a-z]/i, '').truncate(4, omission: '') + "_" + (params[:person][:given_name]).gsub(/[^0-9a-z]/i, '').truncate(3, omission: '') + "_" + (params[:person][:family_name]).gsub(/[^0-9a-z]/i, '').truncate(3, omission: '') + "_" + rand(0..9999).to_s
      else
        params[:person][:username] = "co_" + params[:person][:organization_name].gsub(/[^0-9a-z]/i, '').truncate(11, omission: '') + "_" + rand(0..9999).to_s
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

    # New member notification to admins
    Delayed::Job.enqueue(CommunityJoinedJob.new(@person.id, @current_community.id)) if @current_community


    # If employee ...
    if signup_as == "employee"
      # ... and not invited, then send message & email to company for confirming new employee
      if invitation.nil? || invitation.target != "employee"
        Conversation.manuallyCreateConversation(@current_community, @person.company, @person, t('people.new.message_to_company_owner',:name => @person.full_name, :email => @person.emails.first.address, :profile => person_url(@person.company)))
        PersonMailer.new_employee_notification(@person, @person.company, @current_community, @person.emails.first.address)

      # ... and invited by company admin, then no need for verification by company admin
      else
        @person.employer.update_attribute(:active, true)
      end
    end

    # send email confirmation and redirect to
    # (unless disabled for testing environment)
    if APP_CONFIG.skip_email_confirmation
      email.confirm!

      redirect_to root
    else
      Email.send_confirmation(email, @current_community)

      flash[:notice] = t("layouts.notifications.account_creation_succesful_you_still_need_to_confirm_your_email")
      redirect_to :controller => "sessions", :action => "confirmation_pending", :origin => "email_confirmation"
    end

  end

  def build_devise_resource_from_person(person_params)
    person_params.delete(:terms) #remove terms part which confuses Devise

    # This part is copied from Devise's regstration_controller#create
    build_resource(person_params)
    resource
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
    # Check if new company name and if, then if it already exists
    if params[:person][:organization_name] && (params[:person][:organization_name] != @site_owner.organization_name)
      unless Person.organization_name_available?(params[:person][:organization_name])
        flash[:error] = t("people.show.organization_is_in_use")
        redirect_to :back and return
      end
    end

    # If setting new location, delete old one first
    if params[:person] && params[:person][:location] && (params[:person][:location][:address].empty? || params[:person][:street_address].blank?)
      params[:person].delete("location")
      if @site_owner.location
        @site_owner.location.delete
      end
    end

    # Check that people don't exploit changing email to be confirmed to join an email restricted community
    if params["request_new_email_confirmation"] && @current_community && ! @current_community.email_allowed?(params[:person][:email])
      flash[:error] = t("people.new.email_not_allowed")
      redirect_to :back and return
    end

    @site_owner.set_emails_that_receive_notifications(params[:person][:send_notifications])

    begin
      person_params = params.require(:person).permit(
        :given_name,
        :family_name,
        :organization_name,
        :street_address,
        :phone_number,
        :main_product,
        :location_alias,
        :image,
        :description,
        { location: [:address, :google_address, :latitude, :longitude] },
        :password,
        :password2,
        { send_notifications: [] },
        { email_attributes: [:address] },
        :min_days_between_community_updates,
        { preferences: [
          :email_from_admins,
          :email_about_new_messages,
          :email_about_new_comments_to_own_listing,
          :email_when_conversation_accepted,
          :email_when_conversation_rejected,
          :email_about_new_received_testimonials,
          :email_about_accept_reminders,
          :email_about_confirm_reminders,
          :email_about_testimonial_reminders,
          :email_about_completed_transactions,
          :email_about_new_payments,
          :email_about_payment_reminders,
          :email_about_new_listings_by_followed_people,
        ] }
      )

      Maybe(person_params)[:location].each { |loc|
        person_params[:location] = loc.merge(location_type: :person)
      }

      if @site_owner.update_attributes(person_params)
        if params[:person][:password] && @relation != :rentog_admin && @relation != :domain_supervisor
          #if password changed Devise needs a new sign in.
          sign_in @site_owner, :bypass => true
        end

        if params[:person][:email_attributes] && params[:person][:email_attributes][:address]
          # A new email was added, send confirmation email to the latest address
          Email.send_confirmation(@site_owner.emails.last, @current_community)
        end

        flash[:notice] = t("layouts.notifications.person_updated_successfully")

        # Send new confirmation email, if was changing for that
        if params["request_new_email_confirmation"]
            @site_owner.send_confirmation_instructions(request.host_with_port, @current_community)
            flash[:notice] = t("layouts.notifications.email_confirmation_sent_to_new_address")
        end
      else
        flash[:error] = t("layouts.notifications.#{@site_owner.errors.first}")
      end
    rescue RestClient::RequestFailed => e
      flash[:error] = t("layouts.notifications.update_error")
    end

    redirect_to :back
  end

  def destroy
    has_unfinished = TransactionService::Transaction.has_unfinished_transactions(@site_owner.id)
    return redirect_to root if has_unfinished

    communities = @site_owner.community_memberships.map(&:community_id)

    # Do all delete operations in transaction. Rollback if any of them fails
    ActiveRecord::Base.transaction do
      UserService::API::Users.delete_user(@site_owner.id)
      MarketplaceService::Listing::Command.delete_listings(@site_owner.id)

      communities.each { |community_id|
        PaypalService::API::Api.accounts.delete(community_id: @current_community.id, person_id: @site_owner.id)
      }
    end

    sign_out @site_owner
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

  def change_supervisor_mode
    if @current_user.is_domain_supervisor
      old_val = @current_user.supervisor_mode_active
      @current_user.update_attribute(:supervisor_mode_active, !old_val)
    end

    redirect_to person_poolTool_path(@current_user, domain_view: "1") and return
  end





  private

  # Create a new person by params and current community
  def new_person(params, current_community)
    person = Person.new

    params[:person][:locale] =  params[:locale] || APP_CONFIG.default_locale
    params[:person][:test_group_number] = 1 + rand(4)

    # Remove temporary params before creating a new person
    email = Email.new(:person => person, :address => params[:person][:email].downcase, :send_notifications => true)
    params["person"].delete(:email)
    company_name = params[:person][:company_name]
    params["person"].delete(:company_name)


    person = build_devise_resource_from_person(params[:person])

    person.emails << email

    person.inherit_settings_from(current_community)

    # wah: Change the user type according to the params
    if params[:person][:signup_as] == "organization"
      person.is_organization = true
    elsif params[:person][:signup_as] == "employee"
      person.is_organization = false
      person.company = Person.where('organization_name = ? And deleted = 0',company_name).first
    end

    # wah: Set user plan
    user_plan = UserPlanService::Api.new
    user_plan.set_plan_of_new_user(person)

    if person.save!
      sign_in(resource_name, resource)
    end

    person.set_default_preferences

    # if organization, then also create a new company_option object in db
    if person.is_organization?
      compOpt = CompanyOption.new
      compOpt.company_id = person.id
      compOpt.save
    end

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


  def change_active_status(status)
    @site_owner.update_attribute(:active, (status.eql?("activated") ? true : false))
    @site_owner.listings.update_all(:open => false) if status.eql?("deactivated")
    flash[:notice] = t("layouts.notifications.person_#{status}")
    respond_to do |format|
      format.html {
        redirect_to @site_owner
      }
      format.js {
        render :layout => false
      }
    end
  end

  # Filters out those followed_people that are not members of the community
  # This method is temporary and only needed until the possibility to have
  # one account in many communities is disabled. Then this can be deleted
  # and return to use just simpler followed_people
  # NOTE: similar method is in FollowedPeopleController and should be cleaned too
  def followed_people_in_community(person, community)
    person.followed_people.select{|p| p.member_of?(community)}
  end

end
