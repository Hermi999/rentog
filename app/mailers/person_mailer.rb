# encoding: utf-8

include ApplicationHelper
include PeopleHelper
include ListingsHelper
include TruncateHtmlHelper

class PersonMailer < ActionMailer::Base
  include MailUtils

  # Enable use of method to_date.
  require 'active_support/core_ext'

  require "truncate_html"

  default :from => APP_CONFIG.sharetribe_mail_from_address
  layout 'email'

  add_template_helper(EmailTemplateHelper)

  # This task is expected to be run on daily scheduling
  # It iterates through all overdue and currently active listings to send out
  # user notifications. The overdue bookings are also stored into the overdue
  # bookings table in the db.
  # Optional the user_id can be given for test purposes
  def deliver_device_return_notifications(user_id=nil)
    # Go through all the overdue bookings to store only the latest overdue booking
    # of one user for one specific listing into the users_to_notify_of_overdue array.
    latestOverdueBookingsWithUsers = getLatestOverdueBookingsWithUsers(user_id)


    # Store the latest overdue bookings into db
    # wah: todo ...


    # Get all currently active bookings
    if user_id.nil?
      activeBookings = Booking.getActiveBookings
    else
      activeBookings = Booking.getActiveBookingsOfUser(user_id)
    end

    # Get users to notify because of an overdue
    users_to_notify_of_overdue = getUsersToNotifyOfOverdue(latestOverdueBookingsWithUsers, activeBookings)

    # Get users for same day pre-notification
    users_to_pre_notify_0day = getUsersToPreNotify(Date.today, activeBookings)

    # Get users for 2 days pre-notification
    users_to_pre_notify_2days = getUsersToPreNotify(Date.today + 2, activeBookings)

    # Send emails to users with overdue bookings
    users_to_notify_of_overdue.each do |user_to_notify|
      PersonMailer.device_return_notifications(user_to_notify).deliver
    end

    # Send emails to users where the booking lasts longer than one day and they
    # have to give back the device today
    users_to_pre_notify_0day.each do |user_to_pre_notify_0day|
      PersonMailer.pre_device_return_notification(user_to_pre_notify_0day).deliver
    end

    # Send emails to users where the booking lasts longer than 5 days and they
    # have to give back the device the day after tomorrow
    users_to_pre_notify_2days.each do |user_to_pre_notify_2days|
      PersonMailer.pre_device_return_notification(user_to_pre_notify_2days).deliver
    end
  end


  # Get all users and the devices to notify of an overdue
  def getUsersToNotifyOfOverdue(latestOverdueBookingsWithUsers, activeBookings)
    # Go through all active bookings
    activeBookings.each do |activeBooking|
      current_user = activeBooking.transaction.starter

      # Remove all listings of each user from the latestOverdueBookingsWithUsers
      # array, where there is an active booking. This is
      # because users who have active Bookings will get an extra notification
      # for this listing. They do not have to give back the device yet.
      latestOverdueBookingsWithUsers.each do |user_to_notify|
        if user_to_notify[:user].id == activeBooking.transaction.starter_id
          user_to_notify[:listings].each do |listing|
            if listing[:listing].id == activeBooking.transaction.listing_id
              user_to_notify[:listings].delete(listing)

              if user_to_notify[:listings] == []
                latestOverdueBookingsWithUsers.delete(user_to_notify)
              end
            end
          end
        end
      end
    end

    latestOverdueBookingsWithUsers
  end

  # Get all users and their devices to pre notify for returning the devices
  def getUsersToPreNotify(return_date, activeBookings)
    users_to_pre_notify = []

    # Go through all active bookings
    activeBookings.each do |activeBooking|
      current_user = activeBooking.transaction.starter

      user_already_there = false
      if activeBooking.end_on == return_date
        users_to_pre_notify.each do |pre_notify_user|
            # If user already exists, just add the listing to the listing-array
            if pre_notify_user[:user].id == current_user.id
              pre_notify_user[:listings] << {
                listing: activeBooking.transaction.listing,
                transaction_id: activeBooking.transaction_id,
                return_on: activeBooking.end_on,
                return_token: activeBooking.device_return_token
              }
              user_already_there = true
              break
            end
        end

        # Create new user-booking-pre-notification entry
        unless user_already_there
          new_listing = {
            listing: activeBooking.transaction.listing,
            transaction_id: activeBooking.transaction_id,
            return_on: activeBooking.end_on,
            return_token: activeBooking.device_return_token
          }
          users_to_pre_notify << {
            user: current_user,
            listings: [new_listing]
          }
        end
      end
    end

    users_to_pre_notify
  end


  # Go through all the overdue bookings to store only the latest overdue booking
  # of one user for one specific listing into the users_to_notify_of_overdue array.
  def getLatestOverdueBookingsWithUsers(user_id=nil)
    if user_id.nil?
      overdueBookings = Booking.getOverdueBookings
    else
      overdueBookings = Booking.getOverdueBookingsOfUser(user_id)
    end
    users_to_notify_of_overdue = []


    overdueBookings.each do |booking|
      current_user = booking.transaction.starter
      user_already_there = false

      # Iterate through all existing users_to_notify_of_overdue
      users_to_notify_of_overdue.each do |user_to_notify|

        # If the user is already whithin the array
        if current_user.id == user_to_notify[:user].id

          # Go through all the already attached listings (with an overdue booking)
          # If the listing to the current booking already exists, then just adapt
          # the listings properties. Otherwise attach the listing to the array
          listing_already_there = false
          user_to_notify[:listings].each do |listing|

            # If the listing of this current booking already exists within the array
            if listing[:listing].id == booking.transaction.listing_id

              # If the current booking ends later, then take over it's attributes
              if listing[:return_on] < booking.end_on
                listing[:transaction_id] = booking.transaction_id
                listing[:return_on] = booking.end_on,
                listing[:return_token] = booking.device_return_token
              end

              listing_already_there = true
              break
            end
          end

          # If the listing was not within the array yet
          unless listing_already_there
            user_to_notify[:listings] << {
              listing: booking.transaction.listing,
              transaction_id: booking.transaction_id,
              return_on: booking.end_on,
              return_token: booking.device_return_token
            }
          end

          user_already_there = true
          break
        end
      end

      # If the user was not in the array yet, then create a new user with a new
      # listing
      unless user_already_there
        new_listing = {
          listing: booking.transaction.listing,
          transaction_id: booking.transaction_id,
          return_on: booking.end_on,
          return_token: booking.device_return_token
        }
        users_to_notify_of_overdue << {
          user: current_user,
          listings: [new_listing]
        }
      end
    end

    users_to_notify_of_overdue
  end

  def device_return_notifications(user_to_notify)
    @recipient = user_to_notify[:user]
    @listings = user_to_notify[:listings]
    @community = Community.first

    with_locale(@recipient.locale, @community.locales.map(&:to_sym), @community.id) do

      # Set url params for all the links in the emails
      @url_params = {}
      @url_params[:host] = "#{@community.full_domain}"
      @url_params[:locale] = @recipient.locale
      @url_params[:ref] = "device_return"
      @url_params.freeze # to avoid accidental modifications later

      # Community name link
      @title_link_text = t("emails.community_updates.title_link_text",
                           :community_name => @community.full_name(@recipient.locale))

      subject = t("emails.device_return_notifications.subject")

      # mail delivery method
      if APP_CONFIG.mail_delivery_method == "postmark"
        # Postmark doesn't support bulk emails, so use Sendmail for this
        delivery_method = :sendmail
      else
        delivery_method = APP_CONFIG.mail_delivery_method.to_sym unless Rails.env.test?
      end

      # Send email
      premailer_mail(:to => @recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(@community),
                     :subject => subject,
                     :delivery_method => delivery_method) do |format|
        format.html { render :layout => 'email_blank_layout' }
      end
    end
  end

  def pre_device_return_notification(user_to_pre_notify)
    @recipient = user_to_pre_notify[:user]
    @listings = user_to_pre_notify[:listings]
    @community = Community.first

    with_locale(@recipient.locale, @community.locales.map(&:to_sym), @community.id) do

      # Set url params for all the links in the emails
      @url_params = {}
      @url_params[:host] = "#{@community.full_domain}"
      @url_params[:locale] = @recipient.locale
      @url_params[:ref] = "device_return_pre_notification"
      @url_params.freeze # to avoid accidental modifications later

      # Community name link
      @title_link_text = t("emails.community_updates.title_link_text",
                           :community_name => @community.full_name(@recipient.locale))

      subject = t("emails.pre_device_return_notification.subject")

      # mail delivery method
      if APP_CONFIG.mail_delivery_method == "postmark"
        # Postmark doesn't support bulk emails, so use Sendmail for this
        delivery_method = :sendmail
      else
        delivery_method = APP_CONFIG.mail_delivery_method.to_sym unless Rails.env.test?
      end

      # Send email
      premailer_mail(:to => @recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(@community),
                     :subject => subject,
                     :delivery_method => delivery_method) do |format|
        format.html { render :layout => 'email_blank_layout' }
      end
    end
  end


  def conversation_status_changed(transaction, community)
    @email_type =  (transaction.status == "accepted" ? "email_when_conversation_accepted" : "email_when_conversation_rejected")
    recipient = transaction.other_party(transaction.listing.author)
    set_up_urls(recipient, community, @email_type)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      @transaction = transaction

      if @transaction.payment_gateway == "braintree" ||  @transaction.payment_process == "postpay"
        # Payment url concerns only braintree and postpay, otherwise we show only the message thread
        @payment_url = community.payment_gateway.new_payment_url(@recipient, @transaction, @recipient.locale, @url_params)
      end

      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => t("emails.conversation_status_changed.your_request_was_#{transaction.status}"))
    end
  end

  def new_message_notification(message, community)
    @email_type =  "email_about_new_messages"
    recipient = message.conversation.other_party(message.sender)
    set_up_urls(recipient, community, @email_type)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      @message = message
      sending_params = {:to => recipient.confirmed_notification_emails_to,
                        :subject => t("emails.new_message.you_have_a_new_message", :sender_name => message.sender.name(community)),
                        :from => community_specific_sender(community)}

      premailer_mail(sending_params)
    end
  end

  def new_payment(payment, community)
    @email_type =  "email_about_new_payments"
    @payment = payment
    recipient = @payment.recipient
    set_up_urls(recipient, community, @email_type)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => t("emails.new_payment.new_payment"))
    end
  end

  def receipt_to_payer(payment, community)
    @email_type =  "email_about_new_payments"
    @payment = payment
    recipient = @payment.payer
    set_up_urls(recipient, community, @email_type)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => t("emails.receipt_to_payer.receipt_of_payment"))
    end
  end

  def transaction_confirmed(conversation, community)
    @email_type =  "email_about_completed_transactions"
    @conversation = conversation
    recipient = conversation.seller
    set_up_urls(conversation.seller, community, @email_type)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => t("emails.transaction_confirmed.request_marked_as_#{@conversation.status}"))
    end
  end

  def transaction_automatically_confirmed(conversation, community)
    @email_type =  "email_about_completed_transactions"
    @conversation = conversation
    recipient = conversation.buyer
    set_up_urls(recipient, community, @email_type)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :template_path => 'person_mailer/automatic_confirmation',
                     :subject => t("emails.transaction_automatically_confirmed.subject"))
    end
  end

  def booking_transaction_automatically_confirmed(transaction, community)
    @email_type = "email_about_completed_transactions"
    @transaction = transaction
    recipient = @transaction.buyer
    set_up_urls(recipient, community, @email_type)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      mail(:to => @recipient.confirmed_notification_emails_to,
           :from => community_specific_sender(community),
           :template_path => 'person_mailer/automatic_confirmation',
           :subject => t("emails.booking_transaction_automatically_confirmed.subject"))
    end
  end

  def escrow_canceled_to(conversation, community, to)
    @email_type =  "email_about_canceled_escrow"
    @conversation = conversation
    recipient = conversation.seller
    set_up_urls(recipient, community, @email_type)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      premailer_mail(:to => to,
                     :from => community_specific_sender(community),
                     :subject => t("emails.escrow_canceled.subject")) do |format|
        format.html { render "escrow_canceled" }
      end
    end
  end

  def escrow_canceled(conversation, community)
    escrow_canceled_to(conversation, community, conversation.seller.confirmed_notification_emails_to)
  end

  def admin_escrow_canceled(conversation, community)
    escrow_canceled_to(conversation, community, community.admin_emails.join(","))
  end

  def new_testimonial(testimonial, community)
    @email_type =  "email_about_new_received_testimonials"
    recipient = testimonial.receiver
    set_up_urls(recipient, community, @email_type)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      @testimonial = testimonial
      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => t("emails.new_testimonial.has_given_you_feedback_in_kassi", :name => testimonial.author.name(community)))
    end
  end

  # Remind users of conversations that have not been accepted or rejected
  # NOTE: the not_really_a_recipient is at the same spot in params
  # to keep the call structure similar for reminder mails
  # but the actual recipient is always the listing author.
  def accept_reminder(conversation, not_really_a_recipient, community)
    @email_type = "email_about_accept_reminders"
    recipient = conversation.listing.author
    set_up_urls(recipient, community, @email_type)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      @conversation = conversation
      premailer_mail(:to => @recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => t("emails.accept_reminder.remember_to_accept_request", :sender_name => conversation.other_party(recipient).name(community)))
    end
  end

  # Remind users to pay
  def payment_reminder(conversation, recipient, community)
    @email_type = "email_about_payment_reminders"
    recipient = conversation.payment.payer
    set_up_urls(recipient, community, @email_type)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      @conversation = conversation

      @pay_url = payment_url(conversation, recipient, @url_params)

      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => t("emails.payment_reminder.remember_to_pay", :listing_title => conversation.listing.title))
    end
  end

  # Remind user to fill in payment details
  def payment_settings_reminder(listing, recipient, community)
    set_up_urls(recipient, community)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      @listing = listing
      @recipient = recipient

      if community.payments_in_use?
        @payment_settings_link = payment_settings_url(MarketplaceService::Community::Query.payment_type(community.id), recipient, @url_params)
      end

      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => t("emails.payment_settings_reminder.remember_to_add_payment_details")) do |format|
        format.html {render :locals => {:skip_unsubscribe_footer => true} }
      end
    end
  end

  # Braintree account was approved (via Webhook)
  def braintree_account_approved(recipient, community)
    set_up_urls(recipient, community)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      @recipient = recipient

      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => t("emails.braintree_account_approved.account_ready")) do |format|
        format.html {render :locals => {:skip_unsubscribe_footer => true} }
      end
    end
  end

  # Remind users of conversations that have not been accepted or rejected
  def confirm_reminder(conversation, recipient, community, days_to_cancel)
    @email_type = "email_about_confirm_reminders"
    recipient = conversation.buyer
    set_up_urls(recipient, community, @email_type)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      @conversation = conversation
      @days_to_cancel = days_to_cancel
      escrow = community.payment_gateway && community.payment_gateway.hold_in_escrow
      template = escrow ? "confirm_reminder_escrow" : "confirm_reminder"
      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => t("emails.confirm_reminder.remember_to_confirm_request")) do |format|
        format.html { render template }
      end
    end
  end

  # Remind users to give feedback
  def testimonial_reminder(conversation, recipient, community)
    @email_type = "email_about_testimonial_reminders"
    set_up_urls(recipient, community, @email_type)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      @conversation = conversation
      @other_party = @conversation.other_party(recipient)
      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => t("emails.testimonial_reminder.remember_to_give_feedback_to", :name => @other_party.name(community)))
    end
  end

  def new_comment_to_own_listing_notification(comment, community)
    @email_type = "email_about_new_comments_to_own_listing"
    recipient = comment.listing.author
    set_up_urls(recipient, community, @email_type)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      @comment = comment
      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => t("emails.new_comment.you_have_a_new_comment", :author => comment.author.name(community)))
    end
  end

  def new_comment_to_followed_listing_notification(comment, recipient, community)
    set_up_urls(recipient, community)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      @comment = comment
      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => t("emails.new_comment.listing_you_follow_has_a_new_comment", :author => comment.author.name(community)))
    end
  end

  def new_update_to_followed_listing_notification(listing, recipient, community)
    set_up_urls(recipient, community)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      @listing = listing
      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => t("emails.new_update_to_listing.listing_you_follow_has_been_updated"))
    end
  end

  def new_listing_by_followed_person(listing, recipient, community)
    set_up_urls(recipient, community)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      @listing = listing
      @no_recipient_name = true
      @author_name = listing.author.name(community)
      @listing_url = listing_url(@url_params.merge({:id => listing.id}))
      @translate_scope = [ :emails, :new_listing_by_followed_person ]
      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => t("emails.new_listing_by_followed_person.subject",
                                   :author_name => @author_name,
                                   :community => community.full_name_with_separator(recipient.locale)))
    end
  end

  def invitation_to_kassi(invitation)
    @invitation = invitation
    mail_locale = @invitation.inviter.locale
    @invitation_code_required = invitation.community.join_with_invite_only
    set_up_urls(nil, invitation.community)
    @url_params[:locale] = mail_locale
    with_locale(mail_locale, invitation.community.locales.map(&:to_sym), invitation.community.id) do
      subject = t("emails.invitation_to_kassi.you_have_been_invited_to_kassi", :inviter => invitation.inviter.name(invitation.community), :community => invitation.community.full_name_with_separator(invitation.inviter.locale))
      premailer_mail(:to => invitation.email,
                     :from => community_specific_sender(invitation.community),
                     :subject => subject,
                     :reply_to => invitation.inviter.confirmed_notification_email_to)
    end
  end

  # A message from the community admin to a single community member
  def community_member_email(sender, recipient, email_subject, email_content, community)
    @email_type = "email_from_admins"
    set_up_urls(recipient, community, @email_type)
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do
      @email_content = email_content
      @no_recipient_name = true
      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => email_subject,
                     :reply_to => "\"#{sender.name(community)}\"<#{sender.confirmed_notification_email_to}>")
    end
  end

  # Used to send notification to marketplace admins when somebody
  # gives feedback on marketplace throught the contact us button in menu
  def new_feedback(feedback, community)
    subject = t("feedback.feedback_subject", service_name: community.name(I18n.locale))

    premailer_mail(
      :to => mail_feedback_to(community, APP_CONFIG.feedback_mailer_recipients),
      :from => community_specific_sender(community),
      :subject => subject,
      :reply_to => feedback.email) do |format|
        format.html {
          render locals: {
                   author_name_and_email: feedback_author_name_and_email(feedback.author, feedback.email, community),
                   community_name: community.name(I18n.locale),
                   content: feedback.content
                 }
      }
    end
  end


  def new_test_email(community)
    subject = "Scheduler Test 1"

    premailer_mail(
      :to => "hermann.wagner01@gmx.at",
      :from => community_specific_sender(community),
      :subject => subject,
      :reply_to => community_specific_sender(community))
  end

  # Used to send notification to marketplace admins when somebody
  # signs up on the landing page
  def new_landingpage_email_signup(signupdata, community)
    subject = t("landing_page_signup.subject")

    premailer_mail(
      :to => mail_feedback_to(community, APP_CONFIG.feedback_mailer_recipients),
      :from => community_specific_sender(community),
      :subject => subject,
      :reply_to => signupdata[:email]) do |format|
        format.html {
          render locals: {
                   action: signupdata[:action],
                   email: signupdata[:email],
                   phone: signupdata[:phone],
                   name: signupdata[:name]
                 }
      }
    end
  end


  def mail_feedback_to(community, platform_admin_email)
    if community.feedback_to_admin? && community.admin_emails.any?
      community.admin_emails.join(",")
    else
      platform_admin_email
    end
  end

  # Old layout

  def new_member_notification(person, community, email)
    @community = community
    @no_settings = true
    @person = person
    @email = email
    premailer_mail(:to => @community.admin_emails,
         :from => community_specific_sender(@community),
         :subject => "New member in #{@community.full_name(@person.locale)}")
  end

  def new_employee_notification(employee, company, community, email)
    @community = community
    @no_settings = true
    @employee = employee
    @email = email
    premailer_mail(:to => [company.emails.first.address],
         :from => community_specific_sender(@community),
         :subject => "New employee in #{@community.full_name(@employee.locale)}")
  end

  def email_confirmation(email, community)
    @current_community = community
    @no_settings = true
    @resource = email.person
    @confirmation_token = email.confirmation_token
    @host = community.full_domain
    with_locale(email.person.locale, community.locales.map(&:to_sym) ,community.id) do
      email.update_attribute(:confirmation_sent_at, Time.now)
      premailer_mail(:to => email.address,
                     :from => community_specific_sender(community),
                     :subject => t("devise.mailer.confirmation_instructions.subject"),
                     :template_path => 'devise/mailer',
                     :template_name => 'confirmation_instructions')
    end
  end

  def reset_password_instructions(person, email_address, community)
    set_up_urls(nil, community) # Using nil as recipient, as we don't want auth token here.
    @person = person
    @no_settings = true
    premailer_mail(:to => email_address,
         :from => community_specific_sender(@community),
         :subject => t("devise.mailer.reset_password_instructions.subject")) do |format|
       format.html { render :layout => false }
     end
  end

  def welcome_email(person, community, regular_email=nil, test_email=false)
    @recipient = person
    recipient = person
    with_locale(recipient.locale, community.locales.map(&:to_sym), community.id) do

      @current_community = community

      @regular_email = regular_email
      @url_params = {}
      @url_params[:host] = "#{community.full_domain}"
      @url_params[:locale] = recipient.locale
      @url_params[:ref] = "welcome_email"
      @url_params.freeze # to avoid accidental modifications later
      @test_email = test_email

      if @recipient.has_admin_rights_in?(community) && !@test_email
        subject = t("emails.welcome_email.welcome_email_subject_for_marketplace_creator")
      else
        subject = t("emails.welcome_email.welcome_email_subject", :community => community.full_name(recipient.locale), :person => person.given_name_or_username)
      end
      premailer_mail(:to => recipient.confirmed_notification_emails_to,
                     :from => community_specific_sender(community),
                     :subject => subject) do |format|
        format.html { render :layout => 'email_blank_layout' }
      end
    end
  end

  # A message from the community admin to a community member
  def self.community_member_email_from_admin(sender, recipient, community, email_subject, email_content, email_locale)
    if recipient.should_receive?("email_from_admins") && (email_locale.eql?("any") || recipient.locale.eql?(email_locale))
      begin
        community_member_email(sender, recipient, email_subject, email_content, community).deliver
      rescue => e
        # Catch the exception and continue sending the emails
        ApplicationHelper.send_error_notification("Error sending email to all the members of community #{community.full_name(email_locale)}: #{e.message}", e.class)
      end
    end
  end

  def premailer_mail(opts, &block)
    premailer(mail(opts, &block))
  end

  # This is an ugly method. Ideas how to improve are very welcome.
  # Depending on a class name prevents refactoring.
  def payment_url(conversation, recipient, url_params)
    if conversation.payment.is_a? BraintreePayment
      edit_person_message_braintree_payment_url(url_params.merge({:id => conversation.payment.id, :person_id => recipient.id.to_s, :message_id => conversation.id}))
    else
      new_person_message_payment_url(recipient, url_params.merge({:message_id => conversation.id}))
    end
  end

  private

  def feedback_author_name_and_email(author, email, community)
    present = ->(x) {x.present?}
      case [author, email]
      when matches([present, present])
        "#{PersonViewUtils.person_display_name(author, community)} (#{email})"
      when matches([nil, present])
        "#{t("feedback.unlogged_user")} (#{email})"
      else
        "#{t("feedback.anonymous_user")}"
      end
  end
end
