class BookingsController < ApplicationController
  before_filter :ensure_is_authorized_to_update_booking, :only => [ :update_device_returned]


  def update_device_returned
    Booking.setDeviceReturnedOfOverdueBookingsOfUser(true, @current_user.id, @act_transaction.listing_id)

    respond_to do |format|
      format.json { render :json => {transaction_id: params[:transaction_id], device_returned: @act_transaction.booking.device_returned} }
    end
  end


  def schedule_open_device_returnes
    # Get all open bookings and send emails with a delayed job
    Delayed::Job.enqueue(ReturnBookingReminderJob.new(@current_community.id))

    # Send emails
    #PersonMailer.new_test_email(@current_community).deliver

    # Respond to post request
    respond_to do |format|
      format.json { render :json => {status: "success"} }
    end
  end



  private

    def ensure_is_authorized_to_update_booking
      @act_transaction = Transaction.where('id = ?', params[:transaction_id]).first

      @current_user &&
      ( @current_user == @act_transaction.starter ||            # the creator of the booking
        @current_user == @act_transaction.starter.company ||    # the company of the creator of the booking
        @current_user.has_admin_rights_in?(@current_community)  # the community admin
      )
    end
end
