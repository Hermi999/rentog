class BookingsController < ApplicationController
  before_filter :ensure_is_authorized_to_update_booking, :only => [ :update_device_returned]


  def update_device_returned
    # Get the current and set device_returned status to true
    act_booking = @act_transaction.booking
    act_booking.update_attribute :device_returned, params[:device_returned]


    # get all active bookings where device_returned status is active
    old_bookings = Booking.joins(:transaction).select('bookings.id, bookings.device_returned')
                                              .where("transactions.starter_id = ? AND
                                                      bookings.device_returned = false AND
                                                      bookings.end_on < ?", @current_user.id, act_booking.end_on)
    old_bookings.each do |booking|
      booking.update_attribute :device_returned, params[:device_returned]
    end

    respond_to do |format|
      format.json { render :json => {transaction_id: params[:transaction_id], device_returned: act_booking.device_returned} }
    end
  end

  def schedule_open_device_returnes
    # Get all open bookings

    # Send emails
    PersonMailer.new_test_email(@current_community).deliver

    # Respond to post request
    respond_to do |format|
      format.json { render :json => {status: "success"} }
    end
  end



  private

    def ensure_is_authorized_to_update_booking
      @act_transaction = Transaction.where('id = ?', params[:transaction_id]).first

      @current_user && @current_user == @act_transaction.starter
    end
end
