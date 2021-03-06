# == Schema Information
#
# Table name: people
#
#  id                                 :string(22)       not null, primary key
#  created_at                         :datetime
#  updated_at                         :datetime
#  is_admin                           :integer          default(0)
#  locale                             :string(255)      default("fi")
#  preferences                        :text(65535)
#  active_days_count                  :integer          default(0)
#  last_page_load_date                :datetime
#  test_group_number                  :integer          default(1)
#  active                             :boolean          default(TRUE)
#  username                           :string(255)
#  email                              :string(255)
#  encrypted_password                 :string(255)      default(""), not null
#  reset_password_token               :string(255)
#  reset_password_sent_at             :datetime
#  remember_created_at                :datetime
#  sign_in_count                      :integer          default(0)
#  current_sign_in_at                 :datetime
#  last_sign_in_at                    :datetime
#  current_sign_in_ip                 :string(255)
#  last_sign_in_ip                    :string(255)
#  password_salt                      :string(255)
#  given_name                         :string(255)
#  family_name                        :string(255)
#  phone_number                       :string(255)
#  description                        :text(65535)
#  image_file_name                    :string(255)
#  image_content_type                 :string(255)
#  image_file_size                    :integer
#  image_updated_at                   :datetime
#  image_processing                   :boolean
#  facebook_id                        :string(255)
#  authentication_token               :string(255)
#  community_updates_last_sent_at     :datetime
#  min_days_between_community_updates :integer          default(1)
#  is_organization                    :boolean
#  organization_name                  :string(255)
#  deleted                            :boolean          default(FALSE)
#  pool_tool_color_schema             :string(255)      default("theme_dark")
#  pool_tool_show_legend              :string(255)      default("1")
#  user_plan                          :string(255)      default("free")
#  user_plan_features                 :string(255)
#  main_product                       :string(255)
#  credits                            :integer          default(0)
#  is_domain_supervisor               :boolean          default(FALSE)
#  supervisor_mode_active             :boolean          default(FALSE)
#  description_of_sales_conditions    :string(255)
#  contact_email                      :string(255)
#  website                            :string(255)
#
# Indexes
#
#  index_people_on_authentication_token  (authentication_token)
#  index_people_on_email                 (email) UNIQUE
#  index_people_on_facebook_id           (facebook_id) UNIQUE
#  index_people_on_id                    (id)
#  index_people_on_reset_password_token  (reset_password_token) UNIQUE
#  index_people_on_username              (username) UNIQUE
#

require 'json'
require 'rest_client'
require "open-uri"
require File.expand_path('../../../lib/np_guid/uuid22', __FILE__)

# This class represents a person (a user of Sharetribe).

class Person < ActiveRecord::Base

  include ErrorsHelper
  include ApplicationHelper

  self.primary_key = "id"

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :omniauthable

  if APP_CONFIG.use_asi_encryptor
    require Rails.root.join('lib', 'devise', 'encryptors', 'asi')
    devise :encryptable # to be able to use similar encrypt method as ASI
  end

  # attr_accessor is use for variables that we don't want to store in the
  # database and will only exist for the life of the object.
  attr_accessor :guid, :password2, :form_login,
                :form_given_name, :form_family_name, :form_password,
                :form_password2, :form_email, :consent,
                :input_again, :community_category, :send_notifications,
                :organization_name2, :signup_as, :organization_email,
                :user_type

  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login

  # Attributes named in this macro are protected from mass-assignment, such as
  # new(attributes), update_attributes(attributes), or attributes=(attributes).
  # T assign to them you can use direct writer methods. This is meant to protect
  # sensitive attributes from being overwritten by malicious users tampering with
  # URLs or forms.
  # wah82wi: That doesn't makes sense, since we already have with attr_accessible
  # specified which attributes are whitlisted. The other are per default blacklisted
  attr_protected :is_admin

  # ASSOCIATIONS
  #
  # Wir benötigen also für die 1:n Beziehung Company:Employee, eine has_many :through Beziehung für die Company & eine
  # belongs_to Beziehung für den Employee. „through“ kennzeichnet dass wir das Verhältnis zwischen Company und Employee
  # über ein eigenes weiteres Model umsetzen. Dieses Model heißt „Employment“ und ist im Prinzip nur eine Tabelle mit
  # den Attributen company_id und employee_id welches beides Fremdschlüssel auf jeweils eine person_id sind.

  # An employee (is a person and identified by foreign key 'employee_id') has
  # one company through employers
  #has_many :employers, :class_name => 'Employment', :foreign_key => 'employee_id'
  #has_many :companies, :through => :employers #, :source => :company
  has_one :employer, :class_name => 'Employment', :foreign_key => 'employee_id'
  has_one :company, :through => :employer

  # A company (is a person and identified by foreign key 'company_id') has
  # many employees through employments
  has_many :employments, :foreign_key => 'company_id'
  has_many :employees, :through => :employments
  has_many :listings, -> { where(deleted: 0) }, :dependent => :destroy, :foreign_key => "author_id"
  has_many :emails, :dependent => :destroy, :inverse_of => :person

  has_one :location, -> { where(location_type: :person) }, :dependent => :destroy
  has_one :braintree_account, :dependent => :destroy
  has_one :checkout_account, dependent: :destroy
  has_one :company_option, :dependent => :destroy, :foreign_key => "company_id"

  has_many :participations, :dependent => :destroy
  has_many :conversations, :through => :participations, :dependent => :destroy
  has_many :authored_testimonials, :class_name => "Testimonial", :foreign_key => "author_id", :dependent => :destroy
  has_many :received_testimonials, -> { order("id DESC")}, :class_name => "Testimonial", :foreign_key => "receiver_id", :dependent => :destroy
  has_many :received_positive_testimonials, -> { where("grade IN (0.5,0.75,1)").order("id DESC") }, :class_name => "Testimonial", :foreign_key => "receiver_id"
  has_many :received_negative_testimonials, -> { where("grade IN (0.0,0.25)").order("id DESC") }, :class_name => "Testimonial", :foreign_key => "receiver_id"
  has_many :messages, :foreign_key => "sender_id"
  has_many :authored_comments, :class_name => "Comment", :foreign_key => "author_id", :dependent => :destroy
  has_many :community_memberships, :dependent => :destroy
  has_many :communities, -> { where("community_memberships.status = 'accepted'") }, :through => :community_memberships
  has_many :invitations, :foreign_key => "inviter_id", :dependent => :destroy
  has_many :auth_tokens, :dependent => :destroy
  has_many :follower_relationships
  has_many :followers, :through => :follower_relationships, :foreign_key => "person_id"
  has_many :inverse_follower_relationships, :class_name => "FollowerRelationship", :foreign_key => "follower_id"
  has_many :followed_people, :through => :inverse_follower_relationships, :source => "person"
  has_many :credit_histories, :foreign_key => "person_id", :dependent => :destroy
  has_many :listing_events, :foreign_key => "person_id"
  has_many :listing_requests

  has_and_belongs_to_many :subscribed_listings, :class_name => "Listing", :join_table => "listing_subscribers"  # wah
  has_and_belongs_to_many :custom_fields, class_name: "CustomField"   # wah
  has_and_belongs_to_many :followed_listings, :class_name => "Listing", :join_table => "listing_followers"

  def to_param
    username
  end

  def self.find(username)
    super(self.find_by_username(username).try(:id) || username)
  end

  DEFAULT_TIME_FOR_COMMUNITY_UPDATES = 7.days

  # These are the email notifications, excluding newsletters settings
  EMAIL_NOTIFICATION_TYPES = [
    "email_about_new_messages",
    "email_about_new_comments_to_own_listing",
    "email_when_conversation_accepted",
    "email_when_conversation_rejected",
    "email_about_new_received_testimonials",
    "email_about_accept_reminders",
    "email_about_confirm_reminders",
    "email_about_testimonial_reminders",
    "email_about_completed_transactions",
    "email_about_new_payments",
    "email_about_payment_reminders",
    "email_about_new_listings_by_followed_people"

    # These should not yet be shown in UI, although they might be stored in DB
    # "email_when_new_friend_request",
    # "email_when_new_feedback_on_transaction",
    # "email_when_new_listing_from_friend"
  ]
  EMAIL_NEWSLETTER_TYPES = [
    "email_from_admins"
  ]

  PERSONAL_EMAIL_ENDINGS = ["gmail.com", "hotmail.com", "yahoo.com", "gmx.at", "yahoo.de"]

  serialize :preferences

# Validations
  validates_length_of :phone_number, :maximum => 25, :allow_nil => true, :allow_blank => true
  validates_length_of :username, :within => 3..20
  validates_length_of :organization_name, :within => 3..30, :allow_nil => true, :allow_blank => true
  validates_length_of :given_name, :within => 1..255, :allow_nil => true, :allow_blank => true
  validates_length_of :family_name, :within => 1..255, :allow_nil => true, :allow_blank => true

  validates_format_of :username,
                       :with => /\A[A-Z0-9_]*\z/i

  USERNAME_BLACKLIST = YAML.load_file("#{Rails.root}/config/username_blacklist.yml")
  ORGANIZATION_NAME_BLACKLIST = YAML.load_file("#{Rails.root}/config/organizationname_blacklist.yml")
  THEME_WHITELIST = ["theme_dark", "theme_white", "theme_red"]

  validates :username, :exclusion => USERNAME_BLACKLIST
  validates :pool_tool_color_schema, :inclusion => THEME_WHITELIST
  validate :community_email_type_is_correct

  has_many :import_listings_file, :foreign_key => "author_id", :dependent => :destroy
  has_attached_file :image, :styles => {
                      :medium => "288x288#",
                      :small => "108x108#",
                      :thumb => "48x48#",
                      :original => "600x800>"}

  process_in_background :image

  #validates_attachment_presence :image
  validates_attachment_size :image, :less_than => 9.megabytes
  validates_attachment_content_type :image,
                                    :content_type => ["image/jpeg", "image/png", "image/gif",
                                      "image/pjpeg", "image/x-png"] #the two last types are sent by IE.

  before_validation(:on => :create) do
    self.id = UUID.timestamp_create.to_s22
    set_default_preferences unless self.preferences
  end

  after_save :enableMarketplaceCustomFieldsForCompany



  # Creates a new email
  def email_attributes=(attributes)
    emails.build(attributes)
  end

  def set_emails_that_receive_notifications(email_ids)
    if email_ids
      emails.each do |email|
        email.update_attribute(:send_notifications, email_ids.include?(email.id.to_s))
      end
    end
  end

  # Override Devise's authentication finder method to allow log in with username OR email
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)

      matched = where(conditions).where(username: login.downcase).first

      if matched
        return matched
      else
        e = Email.find_by_address(login.downcase)
        return e.person if e
      end
    else
      where(conditions).first
    end
  end

  def community_email_type_is_correct
    if ["university", "community"].include? community_category
      email_ending = email.split('@')[1]
      if PERSONAL_EMAIL_ENDINGS.include? email_ending
        errors.add(:email, "This looks like a non-organization email address. Remember to use the email of your organization.")
      end
    end
  end

  def last_community_updates_at
    community_updates_last_sent_at || DEFAULT_TIME_FOR_COMMUNITY_UPDATES.ago
  end

  def self.username_blacklist
    USERNAME_BLACKLIST
  end

  def self.username_available?(username)
     !Person.find_by_username(username).present? && !username.in?(USERNAME_BLACKLIST)
  end

  def self.organization_name_available?(organization_name)
    orga = Person.where("organization_name = ? And deleted = 0", organization_name).first

    # There shouldn't be an active organization with the same name AND the organization
    # name shouldn't be on our blacklist
    !orga.present? && !organization_name.in?(ORGANIZATION_NAME_BLACKLIST)
  end

  def self.organization_email_available?(organization_email)
    person = Person.find_by_email(organization_email)
    if !person.nil? && person.is_organization? && !person.deleted
      person
    else
      nil
    end
  end

  # Deprecated: This is view logic (how to display name) and thus should not be in model layer
  # Consider using PersonViewUtils
  def name_or_username(community_or_display_type=nil)
    if community_or_display_type.present? && community_or_display_type.class == Community
      display_type = community_or_display_type.name_display_type
    else
      display_type = community_or_display_type
    end
    if is_organization
      return organization_name
    elsif given_name.present?
      if display_type
        case display_type
        when "first_name_with_initial"
          return first_name_with_initial
        when "first_name_only"
          return given_name
        else
          return full_name
        end
      else
        return first_name_with_initial
      end
    else
      return username
    end
  end

  # Deprecated: This is view logic (how to display name) and thus should not be in model layer
  # Consider using PersonViewUtils
  def full_name(current_community = nil)
    if is_organization
      "#{organization_name}"
    else
      "#{given_name} #{family_name}"
    end
  end

  # Deprecated: This is view logic (how to display name) and thus should not be in model layer
  # Consider using PersonViewUtils
  def first_name_with_initial
    if family_name
      initial = family_name[0,1]
    else
      initial = ""
    end
    "#{given_name} #{initial}"
  end

  # Deprecated: This is view logic (how to display name) and thus should not be in model layer
  # Consider using PersonViewUtils
  def name(community_or_display_type)
    return name_or_username(community_or_display_type)
  end

  # Deprecated: This is view logic (how to display name) and thus should not be in model layer
  # Consider using PersonViewUtils
  def given_name_or_username(no_orga_name = false)
    if is_organization && !no_orga_name
      return organization_name
    elsif given_name.present?
      return given_name
    else
      return username
    end
  end

  def set_given_name(name)
    update_attributes({:given_name => name })
  end

  def set_organization_name(name)
    update_attributes({:organization_name => name })
  end

  def street_address
    if location
      return location.address
    else
      return nil
    end
  end

  def location_alias
    if location
      return location.location_alias
    else
      return nil
    end
  end

  def update_attributes(params)
    if params[:preferences]
      super(params)
    else
      #Handle location information
      if params[:location]
        if self.location && self.location.address != params[:street_address]
          #delete location and create a new one
          self.location.delete
        end

        # Set the address part of the location to be similar to what the user wrote.
        # the google_address field will store the longer string for the exact position.
        params[:location][:address] = params[:street_address] if params[:street_address]

        self.location = Location.new(params[:location].merge("location_alias" => params[:location_alias]))
        params[:location].each {|key| params[:location].delete(key)}
        params.delete(:location)
        params.delete(:location_alias)

      else
        # Update the location alias if it has a value and location is not changed
        if params[:location_alias] && params[:location_alias] != "" && self.location
          self.location.location_alias = params[:location_alias]
          params.delete(:location_alias)
        end
      end

      save
      super(params.except("password2", "street_address", "location_alias"))
    end
  end

  def picture_from_url(url)
    self.image = open(url)
    self.save
  end

  def store_picture_from_facebook()
    if self.facebook_id
      resp = RestClient.get("http://graph.facebook.com/#{self.facebook_id}/picture?type=large&redirect=false")
      url = JSON.parse(resp)["data"]["url"]
      self.picture_from_url(url)
    end
  end

  def offers
    listings.offers
  end

  def requests
    listings.requests
  end

  # The percentage of received testimonials with positive grades
  # (grades between 3 and 5 are positive, 1 and 2 are negative)
  def feedback_positive_percentage_in_community(community)
    # NOTE the filtering with communinity can be removed when
    # user accounts are no more shared among communities
    received_testimonials = TestimonialViewUtils.received_testimonials_in_community(self, community)
    positive_testimonials = TestimonialViewUtils.received_positive_testimonials_in_community(self, community)
    negative_testimonials = TestimonialViewUtils.received_negative_testimonials_in_community(self, community)

    if positive_testimonials.size > 0
      if negative_testimonials.size > 0
        (positive_testimonials.size.to_f/received_testimonials.size.to_f*100).round
      else
        return 100
      end
    elsif negative_testimonials.size > 0
      return 0
    end
  end

  def set_default_preferences
    self.preferences = {}
    EMAIL_NOTIFICATION_TYPES.each { |t| self.preferences[t] = true }
    EMAIL_NEWSLETTER_TYPES.each { |t| self.preferences[t] = true }
    save
  end

  def password2
    if new_record?
      return form_password2 ? form_password2 : ""
    end
  end

  def can_delete_email(email)
    EmailService.can_delete_email(self.emails, email, self.communities.collect(&:allowed_emails))[:result]
  end

  # Returns true if the person has global admin rights in Rentog.
  def is_admin?
    is_admin == 1
  end

  # Returns true if person is a supervisor and in supervisor mode
  def is_supervisor?
    supervisor_mode_active && is_domain_supervisor
  end

  def is_supervisor_of?(person)
    supervisor_domains = self.get_domains
    site_owner_domains = Maybe(person).get_domains.or_else([])

    self.is_supervisor? && (supervisor_domains & site_owner_domains).any?
  end

  def belongs_to_same_domain?(person)
    self.get_companies_with_same_domain.include?(person.get_company)
  end

  # Returns trus if person is a employee
  def is_employee?
    !is_organization
  end

  def is_employee_of?(company_id)
    !is_organization && company.id.eql?(company_id)
  end

  # Starts following a listing
  def follow(listing)
    followed_listings << listing
  end

  # Unfollows a listing
  def unfollow(listing)
    followed_listings.delete(listing)
  end

  # Checks if this user is following the given listing
  def is_following?(listing)
    followed_listings.include?(listing)
  end

  # Updates the user following status based on the given status
  # for the given listing
  def update_follow_status(listing, status)
    # if current user isn't the author of the listing
    #unless id == listing.author.id
      if status
        follow(listing) unless is_following?(listing)
      else
        unfollow(listing) if is_following?(listing)
      end
    #end
  end

  def read(conversation)
    conversation.participations.where(["person_id LIKE ?", self.id]).first.update_attribute(:is_read, true)
  end

  def grade_amounts
    grade_amounts = []
    Testimonial::GRADES.each_with_index do |grade, index|
      grade_amounts[Testimonial::GRADES.size - 1 - index] = [grade[0], received_testimonials.where(:grade => grade[1][:db_value]).count, grade[1][:form_value]]
    end
    return grade_amounts
  end

  def consent(community)
    community_memberships.find_by_community_id(community.id).consent
  end

  def is_admin_of?(community)
    community_membership = community_memberships.find_by_community_id(community.id)
    community_membership && community_membership.admin?
  end

  def is_company_admin_of?(company)
    is_organization and (organization_name == company.organization_name)
  end

  def has_admin_rights_in?(community)
    is_admin? || is_admin_of?(community)
  end

  def should_receive?(email_type)
    confirmed_email = !confirmed_notification_emails.empty?

    if email_type == "community_updates"
      # this is handled outside prefenrences so answer separately
      return active && confirmed_email && min_days_between_community_updates < 100000

    elsif email_type == "email_when_conversation_confirmed_free"
      email_type = "email_when_conversation_accepted"
    end

    active && confirmed_email && preferences && preferences[email_type]
  end

  def profile_info_empty?
    (phone_number.nil? || phone_number.blank?) && (description.nil? || description.blank?) && location.nil?
  end

  def member_of?(community)
    community.members.include?(self)
  end

  def can_post_listings_at?(community)
    self.community_memberships.where(:community_id => community.id).first.can_post_listings
    #CommunityMembership.find_by_person_id_and_community_id(id, community.id).can_post_listings
  end

  def banned_at?(community)
    memberships = self.community_memberships.find_by_community_id(community.id)
    !memberships.nil? && memberships.banned?
  end

  def has_email?(address)
    Email.find_by_address_and_person_id(address, self.id).present?
  end

  def confirmed_notification_emails
    emails.select do |email|
      email.send_notifications && email.confirmed_at.present?
    end
  end

  def confirmed_notification_email_addresses
    self.confirmed_notification_emails.collect(&:address)
  end

  # Notice: If no confirmed notification emails is found, this
  # method returns the first confirmed emails
  def confirmed_notification_emails_to
    send_message_to = EmailService.emails_to_send_message(emails)
    EmailService.emails_to_smtp_addresses(send_message_to)
  end

  # Notice: If no confirmed notification emails is found, this
  # method returns the first confirmed emails
  def confirmed_notification_email_to
    send_message_to = EmailService.emails_to_send_message(emails).first

    Maybe(send_message_to).map { |email|
      EmailService.emails_to_smtp_addresses([email])
    }.or_else(nil)
  end

  # Returns true if the address given as a parameter is confirmed
  def has_confirmed_email?(address)
    email = Email.find_by_address_and_person_id(address, self.id)
    email.present? && email.confirmed_at.present?
  end

  def has_valid_email_for_community?(community)
    community.can_accept_user_based_on_email?(self)
  end

  def self.find_for_facebook_oauth(facebook_data, logged_in_user=nil)
    data = facebook_data.extra.raw_info

    # find if already made facebook connection
    if user = self.find_by_facebook_id(data.id)
      user
    elsif user = logged_in_user || self.find_by_email(data.email)
      # make connection automatically based on email
      user.update_attribute(:facebook_id, data.id)
      if user.image_file_size.nil?
        user.store_picture_from_facebook
      end
      user
    else
      nil
    end
  end

  # Override the default finder to find also based on additional emails
  def self.find_by_email(*args)
    email = Email.find_by_address(*args)
    if email
      email.person
    end
  end

  def reset_password_token_if_needed
    # Devise 3.1.0 doesn't expose methods to generate reset_password_token without
    # sending the email, so this code is copy-pasted from Recoverable module
    raw, enc = Devise.token_generator.generate(self.class, :reset_password_token)
    self.reset_password_token   = enc
    self.reset_password_sent_at = Time.now.utc
    save(:validate => false)
    raw
  end

  # If image_file_name is null, it means the user
  # does not have a profile picture.
  def has_profile_picture?
    image_file_name.present?
  end

  # Tell Devise that email is not required
  def email_required?
    false
  end

  # Tell Devise that email is not required
  def email_changed?
    false
  end

  # A person inherits some default settings from the community in which she is joining
  def inherit_settings_from(current_community)
    # Mark as organization user if signed up through market place which is only for orgs
    self.is_organization = current_community.only_organizations
    self.min_days_between_community_updates = current_community.default_min_days_between_community_updates
  end

  def should_receive_community_updates_now?
    return false unless should_receive?("community_updates")
    # return whether or not enought time has passed. The - 45.minutes is because the sending takes some time so we want
    # 1 day limit to match even if there's 23.55 minutes passed since last sending.
    return true if community_updates_last_sent_at.nil?
    return community_updates_last_sent_at + min_days_between_community_updates.days - 45.minutes < Time.now
  end

  # Return true if this user should use a payment
  # system in this transaction
  def should_pay?(conversation, community)
    conversation.requires_payment?(community) && conversation.status.eql?("accepted") && id.eql?(conversation.buyer.id)
  end

  def pending_email_confirmation_to_join?(membership)
    if membership
      return (membership.status == "pending_email_confirmation")
    else
      return false
    end
  end

  # Returns and email that is pending confirmation
  # If community is given as parameter, in case of many pending
  # emails the one required by the community is returned
  def latest_pending_email_address(community=nil)
    pending_emails = Email.where(:person_id => id, :confirmed_at => nil).pluck(:address)

    allowed_emails = if community && community.allowed_emails
      pending_emails.select do |e|
        community.email_allowed?(e)
      end
    else
      pending_emails
    end

    allowed_emails.last
  end

  def follows?(person)
    followed_people_by_id.include?(person.id)
  end

  def followed_people_by_id
    @followed_people_by_id ||= followed_people.group_by(&:id)
  end

  def self.members_of(community)
    joins(:communities).where("communities.id" => community.id)
  end

  def employs?(person)
    employment = employments.where(employee_id: person.id).first
    if employment
      employment.active?
    end
  end

  def has_to_give_back_device?(community)
    if community.pooltool_employee_has_to_give_back_device
      if is_employee?
        company.company_option && company.company_option.employee_has_to_give_back_listing
      else
        company_option && company_option.employee_has_to_give_back_listing
      end
    else
      false
    end
  end

  def is_allowed_to_book_in_past?
    if is_employee?
      company.company_option && company.company_option.pool_tool_modify_past
    else
      company_option && company_option.pool_tool_modify_past
    end
  end

  def get_company
    if self.is_employee?
      company
    else
      self
    end
  end

  def get_company_name
    get_company.organization_name
  end

  def get_company_members
    comp = self.get_company
    [comp] + comp.employees
  end

  def get_domains
    self.confirmed_notification_email_addresses.map {|address| address.split("@").last}
  end

  def get_companies_with_same_domain
    supervisor_domains = self.get_domains

    supervisor_domains.map! {|domain| "%" + domain}
    domain_emails = Email.where('address LIKE ?', supervisor_domains)

    companies_in_same_domain = []
    domain_emails.each do |email|
      if Email.confirmed?(email.address) && email.person.is_organization
        companies_in_same_domain << email.person
      end
    end
    companies_in_same_domain
  end


  def enableMarketplaceCustomFieldsForCompany
    return if main_product != "marketplace"

    id1 = Maybe(CustomFieldName.where('value like ?', "%Shipment to%").first).custom_field_id.or_else(nil)
    self.custom_fields << CustomField.where(:id => id1).first if id1

    id2 = Maybe(CustomFieldName.where('value like ?', "%Unique Selling Proposition 1%").first).custom_field_id.or_else(nil)
    self.custom_fields << CustomField.where(:id => id2).first if id2

    id3 = Maybe(CustomFieldName.where('value like ?', "%Unique Selling Proposition 2%").first).custom_field_id.or_else(nil)
    self.custom_fields << CustomField.where(:id => id3).first if id3

    id4 = Maybe(CustomFieldName.where('value like ?', "%Unique Selling Proposition 3%").first).custom_field_id.or_else(nil)
    self.custom_fields << CustomField.where(:id => id4).first if id4

    id5 = Maybe(CustomFieldName.where('value like ?', "%Model%").first).custom_field_id.or_else(nil)
    self.custom_fields << CustomField.where(:id => id5).first if id5

    id6 = Maybe(CustomFieldName.where('value like ?', "%Warranty%").first).custom_field_id.or_else(nil)
    self.custom_fields << CustomField.where(:id => id6).first if id6

    id7 = Maybe(CustomFieldName.where('value like ?', "%Additional features and services%").first).custom_field_id.or_else(nil)
    self.custom_fields << CustomField.where(:id => id7).first if id7

    #id8 = Maybe(CustomFieldName.where('value like ?', "%Weight%").first).custom_field_id.or_else(nil)
    #self.custom_fields << CustomField.where(:id => id8).first if id8

    #id9 = Maybe(CustomFieldName.where('value like ?', "%Height%").first).custom_field_id.or_else(nil)
    #self.custom_fields << CustomField.where(:id => id9).first if id9

    #id10 = Maybe(CustomFieldName.where('value like ?', "%Width%").first).custom_field_id.or_else(nil)
    #self.custom_fields << CustomField.where(:id => id10).first if id10

    #id11 = Maybe(CustomFieldName.where('value like ?', "%Depth%").first).custom_field_id.or_else(nil)
    #self.custom_fields << CustomField.where(:id => id11).first if id11

    id12 = Maybe(CustomFieldName.where('value like ?', "%alternative%").first).custom_field_id.or_else(nil)
    self.custom_fields << CustomField.where(:id => id12).first if id12


    # Remove duplicates
    self.custom_fields = self.custom_fields.uniq
  end

end
