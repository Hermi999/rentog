class PersonMessagesController < ApplicationController

  before_filter do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_send_a_message")
  end

  before_filter :fetch_recipient

  def new
    @conversation = Conversation.new

    # A renting request from an employee
    if params[:start_on]
      start_date = params[:start_on]
      end_date = params[:end_on]
      device_link = listings_url(params[:listing_id])
      @message_text = t("person_messages.renting_request", :device_link => device_link, :start_date => start_date, :end_date => end_date)
    else
      @message_text = ""
    end
  end

  def create
    @conversation = new_conversation
    if @conversation.save
      flash[:notice] = t("layouts.notifications.message_sent")
      Delayed::Job.enqueue(MessageSentJob.new(@conversation.messages.last.id, @current_community.id))
      redirect_to @recipient
    else
      flash[:error] = "Sending the message failed. Please try again."
      redirect_to root
    end
  end

  private

  def new_conversation
    conversation_params = params.require(:conversation).permit(
      message_attributes: :content
    )
    conversation_params[:message_attributes][:sender_id] = @current_user.id

    conversation = Conversation.new(conversation_params.merge(community: @current_community))
    conversation.build_starter_participation(@current_user)
    conversation.build_participation(@recipient)
    conversation
  end

  def fetch_recipient
    @recipient = Person.find(params[:person_id])
    if @current_user == @recipient
      flash[:error] = t("layouts.notifications.you_cannot_send_message_to_yourself")
      redirect_to root
    end
  end
end
