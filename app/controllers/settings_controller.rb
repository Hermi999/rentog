class SettingsController < ApplicationController

  before_filter :except => :unsubscribe do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_view_your_settings")
  end

  before_filter :except => :unsubscribe do |controller|
    controller.ensure_authorized t("layouts.notifications.you_are_not_authorized_to_view_this_content")
  end

  before_filter do
    @is_member_of_company = (@relation == :company_admin_own_site || @relation == :company_employee || @relation == :rentog_admin_own_site)
  end

  def show
    flash.now[:notice] = t("settings.profile.image_is_processing") if @site_owner.image.processing?
    @selected_left_navi_link = "profile"
    add_location_to_person
  end

  def account
    @selected_left_navi_link = "account"
    @site_owner.emails.build
    marketplaces = @site_owner.community_memberships
                   .map { |m| Maybe(m.community).name(I18n.locale).or_else(nil) }
                   .compact
    has_unfinished = TransactionService::Transaction.has_unfinished_transactions(@site_owner.id)

    render locals: {marketplaces: marketplaces, has_unfinished: has_unfinished}
  end

  def notifications
    @selected_left_navi_link = "notifications"
  end

  def payments
    @selected_left_navi_link = "payments"
  end

  def pooltool
    if @site_owner && @site_owner.is_organization?
      @selected_left_navi_link = "pooltool"
    else
      redirect_to root and return
    end
  end

  def unsubscribe
    case @relation
      when :rentog_admin, :domain_supervisor
        person = @site_owner
      else
        person = @current_user
      end

    @person_to_unsubscribe = find_person_to_unsubscribe(person, params[:auth])

    if @person_to_unsubscribe && @person_to_unsubscribe.username == params[:person_id] && params[:email_type].present?
      if params[:email_type] == "community_updates"
        MarketplaceService::Person::Command.unsubscribe_person_from_community_updates(@person_to_unsubscribe.id)
      elsif [Person::EMAIL_NOTIFICATION_TYPES, Person::EMAIL_NEWSLETTER_TYPES].flatten.include?(params[:email_type])
        @person_to_unsubscribe.preferences[params[:email_type]] = false
        @person_to_unsubscribe.save!
      else
        @unsubscribe_successful = false
        render :unsubscribe, :status => :bad_request and return
      end
      @unsubscribe_successful = true
      render :unsubscribe
    else
      @unsubscribe_successful = false
      render :unsubscribe, :status => :unauthorized
    end
  end

  private

  def add_location_to_person
    unless @site_owner.location
      @site_owner.build_location(:address => @site_owner.street_address)
      @site_owner.location.search_and_fill_latlng
    end
  end

  def find_person_to_unsubscribe(person, auth_token)
    person || Maybe(AuthToken.find_by_token(auth_token)).person.or_else { nil }
  end

end
