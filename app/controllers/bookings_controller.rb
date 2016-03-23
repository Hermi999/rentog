class BookingsController < ApplicationController
  before_filter :ensure_is_authorized_to_update_booking
  before_filter :check_if_device_is_not_returned_yet, :only => [:update_device_returned]

  # wah: Handles at the moment PUT & GET requests
  def update_device_returned
    # update device returned for all past bookings of this listing and this user
    Booking.setDeviceReturnedOfOverdueBookingsOfUser(true, @current_user.id, @act_transaction.listing_id)

    # update end date of the booking which was latest active
    @act_transaction.booking.return!

    # return success as json if update via pool tool
    if params[:referrer] != "email"
      respond_to do |format|
        format.json { render :json => {transaction_id: params[:transaction_id], device_returned: @act_transaction.booking.device_returned} }
      end
    else
      flash[:notice] = t("pool_tool.show.device_return_successful_email_flash", :title => @act_transaction.listing.title).html_safe
      if @current_user
        redirect_to person_poolTool_path(@current_user)
      else
        redirect_to landingpage_path
      end
    end
  end


  private

    def ensure_is_authorized_to_update_booking
      @act_transaction = Transaction.where('id = ?', params[:transaction_id]).first

      # If user updates via  pooltool, browser and user is logged in
      if @current_user
        if (@current_user == @act_transaction.starter ||            # is the creator of the booking
            @current_user == @act_transaction.starter.company ||    # is the company of the creator of the booking
            @current_user == @act_transaction.author ||             # is author of the listing
            @current_user.has_admin_rights_in?(@current_community)) # is the community admin
          return
        end
      # If user updates via email and token
      else
        if (params[:token] == @act_transaction.booking.device_return_token)
          @current_user = Person.find_by_id params[:uid]
          return
        end
      end

      redirect_to root and return
    end

    def check_if_device_is_not_returned_yet
      if @act_transaction.booking.device_returned == true
        flash[:error] = t("pool_tool.show.device_return_fail_email_flash", :title => @act_transaction.listing.title).html_safe
        if @current_user
          redirect_to person_poolTool_path(@current_user)
        else
          redirect_to landingpage_path
        end
      end
    end
end
