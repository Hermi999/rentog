class FeedbacksController < ApplicationController

  skip_filter :check_confirmations_and_verifications
  skip_filter :cannot_access_without_joining

  FeedbackForm = FormUtils.define_form("Feedback",
                                       :content,
                                       :title,
                                       :url, # referrer
                                       :email
  ).with_validations {
    validates_presence_of :content
  }

  def new
    render_form
  end

  def create
    # Contact me, Newsletter, Voucher request
    if params[:type]

      signupdata = {
        action: params[:type],
        email: params[:email],
        phone: params[:phone]
      }

      PersonMailer.new_landingpage_email_signup(signupdata, @current_community).deliver

      respond_to do |format|
        format.json { render :json => {response: "success"} }
      end

    else
      # User Feedback from Feedback formular
      feedback_form = FeedbackForm.new(params[:feedback])
      return if ensure_not_spam!(params[:feedback], feedback_form)

      unless feedback_form.valid?
        flash[:error] = t("layouts.notifications.feedback_not_saved") # feedback_form.errors.full_messages.join(", ")
        return render_form(feedback_form)
      end

      author_id = Maybe(@current_user).id.or_else("Anonymous")
      email = current_user_email || feedback_form.email

      feedback = Feedback.create(
        feedback_form.to_hash.merge({
                                      community_id: @current_community.id,
                                      author_id: author_id,
                                      email: email
                                    }))

      PersonMailer.new_feedback(feedback, @current_community).deliver

      flash[:notice] = t("layouts.notifications.feedback_saved")

      if Community.first.only_pool_tool
        if @current_user
          if @current_user.is_organization
            redirect_to person_poolTool_path(:person_id => @current_user.username) and return
          else
            redirect_to person_poolTool_path(:person_id => @current_user.company.username) and return
          end
        else
          redirect_to landingpage_path and return
        end
      else
        redirect_to root and return
      end
    end
  end

  private

  def render_form(form = nil)
    render action: :new, locals: feedback_locals(form)
  end

  def feedback_locals(feedback_form)
    {
      email_present: current_user_email.present?,
      feedback_form: feedback_form || FeedbackForm.new(title: nil) # title is honeypot
    }
  end

  def current_user_email
    Maybe(@current_user).confirmed_notification_email_to.or_else(nil)
  end

  # Return truthy if is spam
  def ensure_not_spam!(params, feedback_form)
    if spam?(params[:content], params[:title])
      flash[:error] = t("layouts.notifications.feedback_considered_spam")
      return render_form(feedback_form)
    else
      false
    end
  end

  def link_tags?(str)
    str.include?("[url=") || str.include?("<a href=")
  end

  def too_many_urls?(str)
    str.scan("http://").count > 10
  end

  # Detect most usual spam messages
  def spam?(content, honeypot)
    honeypot.present? || link_tags?(content) || too_many_urls?(content)
  end
end
