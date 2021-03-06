class AcceptConversationsController < ApplicationController

  before_filter do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_accept_or_reject")
  end

  before_filter :fetch_conversation
  before_filter :fetch_listing

  before_filter :ensure_is_author

  # Skip auth token check as current jQuery doesn't provide it automatically
  skip_before_filter :verify_authenticity_token

  MessageForm = Form::Message

  def accept
    prepare_accept_or_reject_form
    @action = "accept"

    if @requester_needs_to_pay
      path_to_payment_settings = payment_settings_path(@current_community.payment_gateway.gateway_type, @current_user)
    end
    render(locals: { path_to_payment_settings: path_to_payment_settings, message_form: MessageForm.new })
  end

  def reject
    prepare_accept_or_reject_form

    @action = "reject"
    if @requester_needs_to_pay
      path_to_payment_settings = payment_settings_path(@current_community.payment_gateway.gateway_type, @current_user)
    end
    render(:accept, locals: { path_to_payment_settings: path_to_payment_settings, message_form: MessageForm.new })
  end

  # Handles accept and reject forms
  def acceptance
    # Update first everything else than the status, so that the payment is in correct
    # state before the status change callback is called
    if @listing_conversation.update_attributes(params[:listing_conversation].except(:status))
      # create a message if user wrote an additional message. If no message
      # the message object will contain errors and will not be valid
      message = MessageForm.new(params[:message].merge({ conversation_id: @listing_conversation.id }))
      if(message.valid?)
        @listing_conversation.conversation.messages.create({content: message.content}.merge(sender_id: @current_user.id))
      end

      # If a non monetary conversation?
      if @listing_conversation.status == "pending_free"
        if params[:listing_conversation][:status] == "accepted"
          params[:listing_conversation][:status] = "confirmed_free"
        end
      end

      # transition_to :accepted
      MarketplaceService::Transaction::Command.transition_to(@listing_conversation.id, params[:listing_conversation][:status])
      MarketplaceService::Transaction::Command.mark_as_unseen_by_other(@listing_conversation.id, @current_user.id)

      flash[:notice] = t("layouts.notifications.request_#{params[:listing_conversation][:status]}")
      redirect_to person_transaction_path(:person_id => @current_user.id, :id => @listing_conversation.id)
    else
      flash[:error] = t("layouts.notifications.something_went_wrong")
      redirect_to person_transaction_path(@current_user, @listing_conversation)
    end
  end

  private

  def prepare_accept_or_reject_form
    @requester_needs_to_pay = FollowerRelationship.payment_necessary?(@listing_conversation.author, @listing_conversation.starter_id) || @listing.get_listing_type != "trusted"

    if @requester_needs_to_pay
      @payment = @current_community.payment_gateway.new_payment
      @payment.community = @current_community
      @payment.default_sum(@listing_conversation.listing, Maybe(@current_community).vat.or_else(0))

      @payout_registration_missing = PaymentRegistrationGuard.new(@current_community, @current_user, @listing).requires_registration_before_accepting?
    end
  end

  def ensure_is_author
    unless @listing.author == @current_user
      flash[:error] = "Only listing author can perform the requested action"
      redirect_to (session[:return_to_content] || root)
    end
  end

  def fetch_listing
    @listing = @listing_conversation.listing
  end

  def fetch_conversation
    @listing_conversation = Transaction.find(params[:id])
  end
end
