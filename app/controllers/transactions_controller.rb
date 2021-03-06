class TransactionsController < ApplicationController

  before_filter only: [:show] do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_view_your_inbox")
  end

  before_filter do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_do_a_transaction")
  end

  before_filter :get_booking_to_edit, :only => [:update, :destroy]
  before_filter :get_current_user_listing_owner_relation, :only => [:new, :create, :update, :destroy]
  before_filter :is_authorized_for_starting_transaction, :only => [:new, :create]
  before_filter :is_authorized_for_changing_pool_tool_booking, :only => [:update, :destroy]


  MessageForm = Form::Message

  TransactionForm = EntityUtils.define_builder(
    [:listing_id, :fixnum, :to_integer, :mandatory],
    [:message, :string],
    [:quantity, :fixnum, :to_integer, default: 1],
    [:start_on, transform_with: ->(v) { Maybe(v).map { |d| TransactionViewUtils.parse_booking_date(d) }.or_else(nil) } ],
    [:end_on, transform_with: ->(v) { Maybe(v).map { |d| TransactionViewUtils.parse_booking_date(d) }.or_else(nil) } ]
  )

  PoolToolTransactionForm = EntityUtils.define_builder(
    [:listing_id, :fixnum, :to_integer, :mandatory],
    [:start_on, transform_with: ->(v) { Maybe(v).map { |d| TransactionViewUtils.parse_booking_date(d) }.or_else(nil) } ],
    [:end_on, transform_with: ->(v) { Maybe(v).map { |d| TransactionViewUtils.parse_booking_date(d) }.or_else(nil) } ]
  )


  def new
    # Check if start-on and end-on dates are valid
    if !bookingDatesValid?
      flash[:error] = t("transactions.already_booked_for_this_date")
      redirect_to (session[:return_to_content] || root) and return
    end

    Result.all(
      ->() {
        fetch_data(params[:listing_id])
      },
      ->((listing_id, listing_model)) {
        ensure_can_start_transactions(listing_model: listing_model, current_user: @current_user, current_community: @current_community)
      }
    ).on_success { |((listing_id, listing_model, author_model, process, gateway))|
      booking = listing_model.unit_type == :day

      transaction_params = HashUtils.symbolize_keys({listing_id: listing_model.id}.merge(params.slice(:start_on, :end_on, :quantity, :delivery)))

      case [process[:process], gateway, booking]
      when matches([:none])
        render_free(listing_model: listing_model, author_model: author_model, community: @current_community, params: transaction_params)
      when matches([:preauthorize, __, true])
        redirect_to book_path(transaction_params)
      when matches([:preauthorize, :paypal])
        redirect_to initiate_order_path(transaction_params)
      when matches([:preauthorize, :braintree])
        redirect_to preauthorize_payment_path(transaction_params)
      when matches([:postpay])
        redirect_to post_pay_listing_path(transaction_params)
      else
        opts = "listing_id: #{listing_id}, payment_gateway: #{gateway}, payment_process: #{process}, booking: #{booking}"
        raise ArgumentError.new("Cannot find new transaction path to #{opts}")
      end
    }.on_error { |error_msg, data|
      flash[:error] = Maybe(data)[:error_tr_key].map { |tr_key| t(tr_key) }.or_else("Could not start a transaction, error message: #{error_msg}")
      redirect_to (session[:return_to_content] || root)
    }
  end

  def create
    poolTool = false
    poolTool = true if params[:employee] || params[:renter]
    validDates = bookingDatesValid?

    # Check if we are in Pool Tool & have a pool tool transaction
    if poolTool
      create_poolToolTransaction(validDates)

    else
      if !bookingDatesValid?
        flash[:error] = t("transactions.already_booked_for_this_date")
        redirect_to (session[:return_to_content] || root) and return
      end

      Result.all(
        ->() {
          TransactionForm.validate(params)
        },
        ->(form) {
          fetch_data(form[:listing_id])
        },
        ->(form, (_, _, _, process)) {
          validate_form(form, process)
        },
        ->(_, (listing_id, listing_model), _) {
          ensure_can_start_transactions(listing_model: listing_model, current_user: @current_user, current_community: @current_community)
        },
        ->(form, (listing_id, listing_model, author_model, process, gateway), _, _) {
          booking_fields = Maybe(form).slice(:start_on, :end_on).select { |booking| booking.values.all? }.or_else({})

          quantity = Maybe(booking_fields).map { |b| DateUtils.duration_days(b[:start_on], b[:end_on]) }.or_else(form[:quantity])

          TransactionService::Transaction.create(
            {
              transaction: {
                community_id: @current_community.id,
                listing_id: listing_id,
                listing_title: listing_model.title,
                starter_id: @current_user.id,
                listing_author_id: author_model.id,
                unit_type: listing_model.unit_type,
                unit_price: listing_model.price,
                unit_tr_key: listing_model.unit_tr_key,
                listing_quantity: quantity,
                content: form[:message],
                booking_fields: booking_fields,
                payment_gateway: process[:process] == :none ? :none : gateway, # TODO This is a bit awkward
                payment_process: process[:process],
                transaction_type: "extern"}   # wah
            })
        }
      ).on_success { |(_, (_, _, _, process), _, _, tx)|
        after_create_actions!(process: process, transaction: tx[:transaction], community_id: @current_community.id)
        flash[:notice] = after_create_flash(process: process) # add more params here when needed
        redirect_to after_create_redirect(process: process, starter_id: @current_user.id, transaction: tx[:transaction]) # add more params here when needed
      }.on_error { |error_msg, data|
        flash[:error] = Maybe(data)[:error_tr_key].map { |tr_key| t(tr_key) }.or_else("Could not start a transaction, error message: #{error_msg}")
        redirect_to (session[:return_to_content] || root)
      }
    end
  end

  def create_poolToolTransaction(validDates)
    # Check if booking dates are valid for selected listing
    if !validDates
      error_message = t("pool_tool.invalid_booking_dates")
      render :json => {
          status: "error",
          error_code: "invalid_dates",
          error_message: error_message
        } and return
    end

    # Determine if employee or another reason for booking was choosen
    if @relation == :trusted_company_admin || @relation == :full_trusted_company_admin
      empl_or_reason = @current_user.organization_name
      params[:employee] = nil
      type = "trustedCompany"

    elsif @relation == :trusted_company_employee || @relation == :full_trusted_company_employee
      employee = Person.where(username: params[:employee][:username]).first
      empl_or_reason = employee[:family_name] + " " + employee[:given_name] + " (" + employee.company.organization_name + ")"
      type = "trustedEmployee"

    else
      if params[:employee]
        employee = Person.where(username: params[:employee][:username]).first
        empl_or_reason = employee[:family_name] + " " + employee[:given_name]
        type = "ownEmployee"

      elsif params[:renter]
        empl_or_reason = params[:renter]
        type = "otherReason"

      else
        flash[:error] = "Something went wrong"
        redirect_to root and return
      end
    end

    # CHECK:
    # Company and trusted employ is not allowed to make transaction for anyone else then himself
    if @relation == :company_employee || @relation == :trusted_company_employee || @relation == :full_trusted_company_employee
      unless @current_user == employee
        flash[:error] = "Access denied"
        redirect_to root and return
      end
    end

    # CHECK:
    # Trusted company admin, is only allowed to make transactions for own employees & himself
    if @relation == :trusted_company_admin || @relation == :full_trusted_company_admin
      if employee && employee.company != @current_user
        flash[:error] = "Access denied"
        redirect_to root and return
      end
    end


    # Starter is either the employee or the current user (= company)
    starter_id =
      if employee
        employee.id
      else
        @current_user.id
      end


    # Handle new bookings which do not have an employee, but another reason
    Result.all(
      ->() {
        PoolToolTransactionForm.validate(params)
      },
      ->(form) {
        # Returns: Result::Success([listing_id, listing_model, author, process, gateway])
        fetch_data(form[:listing_id])
      },
      ->(_, (listing_id, listing_model)) {
        ensure_can_start_transactions(listing_model: listing_model, current_user: @current_user, current_community: @current_community, poolTool: true)
      },
      ->(form, (listing_id, listing_model, author_model, process, gateway), _) {
        booking_fields = Maybe(form).slice(:start_on, :end_on).select { |booking| booking.values.all? }.or_else({})

        # Add reason if not an employee was choosen
        if !params[:employee]
          booking_fields[:reason] = empl_or_reason
        end

        # Pool tool booking is always confirmed
        booking_fields[:confirmed] = true

        # Add description
        if params[:description]
          booking_fields[:description] = params[:description]
        end

        # If booking is in the past or the user does not have to actively give back
        # his booked devices, then set 'device_returned' to true
        if booking_fields[:end_on] < Date.today ||
          !@current_user.has_to_give_back_device?(@current_community)
          booking_fields[:device_returned] = true
        end

        quantity = Maybe(booking_fields).map { |b| DateUtils.duration_days(b[:start_on], b[:end_on]) }.or_else(form[:quantity])

        TransactionService::Transaction.create(
          {
            transaction: {
              community_id: @current_community.id,
              listing_id: listing_id,
              listing_title: listing_model.title,
              starter_id: starter_id,
              listing_author_id: author_model.id,
              listing_quantity: quantity,
              content: form[:message],
              booking_fields: booking_fields,
              payment_gateway: :none,
              payment_process: :none,
              transaction_type: "intern"}
          })
      }
    ).on_success { |(_, (_, _, _, process), _, tx)|
      # wah - add this event to the events table
      if @current_user.id == starter_id
        ListingEvent.create({person_id: @current_user.id, listing_id: params[:listing_id], booking_id: Booking.last.id, event_name: "booking_created"})
      else
        ListingEvent.create({person_id: starter_id, listing_id: params[:listing_id], booking_id: Booking.last.id, event_name: "booking_created_for_employee"})
      end

      # Renter json-response with the new data stored in the db
      render :json => {
        status: "success",
        type: type,
        empl_or_reason: empl_or_reason,
        start_on: params[:start_on],
        end_on: params[:end_on],
        listing_id: params[:listing_id],
        transaction_id: Transaction.last.id,
        renter_id: starter_id,
        description: params[:description]
      } and return


    }.on_error { |error_msg, data|
      flash[:error] = Maybe(data)[:error_tr_key].map { |tr_key| t(tr_key) }.or_else("Could not start a transaction, error message: #{error_msg}")
      redirect_to (session[:return_to_content] || root)
    }
  end

  # wah: Only for Pool Tool
  def update
    # Get new start and end date
    start_day = Date.parse(params[:from])
    end_day = Date.parse(params[:to])

    # Check if booking dates are valid
    if !bookingDatesValid?( start_day.to_s,
                            end_day.to_s,
                            @booking.tx.listing_id,
                            @booking[:start_on],
                            @booking[:end_on])
      error_message = t("pool_tool.invalid_booking_dates")
      render :json => {
        action: "update",
        status: "error",
        message: error_message
      } and return
    end

    ListingEvent.create({person_id: @current_user.id, listing_id: @booking.tx.listing_id , booking_id: @booking.id, event_name: "booking_updated"})

    # Update booking with the corresponding transaction id
    @booking[:start_on] = start_day
    @booking[:end_on] = end_day
    @booking[:description] = params[:desc]
    @booking.save!

    # Check if booking is active or in future, if yes, then set device_returned
    # to false, because the user couldn't already give back the device
    if @booking.is_active? || @booking.is_in_future?
      @booking.update_attribute :device_returned, false
    end

    # Render response
    render :json => {
          action: "update",
          status: "success"
        } and return
  end

  # wah: Only for Pool Tool
  def destroy

    # wah - add this event to the events table
    if @current_user
      ListingEvent.create({person_id: @current_user.id, listing_id: @booking.tx.listing_id, booking_id: @booking.id, event_name: "booking_deleted"})
    end

    # Delete booking with the corresponding transaction id
    #@booking.delete
    #@booking.tx.conversation.delete
    #@booking.tx.delete
    #@booking.tx.update_attribute(:current_state, :canceled)
    #MarketplaceService::Transaction::Command.transition_to(@booking.tx.id, "canceled")
    @booking.tx.update_attribute(:deleted, true)

    # Render response
    render :json => {
          action: "delete",
          status: "success"
        } and return
  end

  def show
    m_participant =
      Maybe(
        MarketplaceService::Transaction::Query.transaction_with_conversation(
        transaction_id: params[:id],
        person_id: @current_user.id,
        community_id: @current_community.id))
      .map { |tx_with_conv| [tx_with_conv, :participant] }

    m_admin =
      Maybe(@current_user.has_admin_rights_in?(@current_community))
      .select { |can_show| can_show }
      .map {
        MarketplaceService::Transaction::Query.transaction_with_conversation(
          transaction_id: params[:id],
          community_id: @current_community.id)
      }
      .map { |tx_with_conv| [tx_with_conv, :admin] }

    transaction_conversation, role = m_participant.or_else { m_admin.or_else([]) }

    tx = TransactionService::Transaction.get(community_id: @current_community.id, transaction_id: params[:id])
         .maybe()
         .or_else(nil)

    unless tx.present? && transaction_conversation.present?
      flash[:error] = t("layouts.notifications.you_are_not_authorized_to_view_this_content")
      return redirect_to root
    end

    tx_model = Transaction.where(id: tx[:id]).first
    conversation = transaction_conversation[:conversation]
    listing = Listing.where(id: tx[:listing_id]).first

    messages_and_actions = TransactionViewUtils::merge_messages_and_transitions(
      TransactionViewUtils.conversation_messages(conversation[:messages], @current_community.name_display_type),
      TransactionViewUtils.transition_messages(transaction_conversation, conversation, @current_community.name_display_type))

    MarketplaceService::Transaction::Command.mark_as_seen_by_current(params[:id], @current_user.id)

    is_author =
      if role == :admin
        true
      else
        listing.author_id == @current_user.id
      end

    render "transactions/show", locals: {
      messages: messages_and_actions.reverse,
      transaction: tx,
      listing: listing,
      transaction_model: tx_model,
      conversation_other_party: person_entity_with_url(conversation[:other_person]),
      is_author: is_author,
      role: role,
      can_book_for_free: !FollowerRelationship.payment_necessary?(listing.author, tx_model.starter_id),
      message_form: MessageForm.new({sender_id: @current_user.id, conversation_id: conversation[:id]}),
      message_form_action: person_message_messages_path(@current_user, :message_id => conversation[:id]),
      price_break_down_locals: price_break_down_locals(tx)
    }
  end

  def op_status
    process_token = params[:process_token]

    resp = Maybe(process_token)
      .map { |ptok| paypal_process.get_status(ptok) }
      .select(&:success)
      .data
      .or_else(nil)

    if resp
      render :json => resp
    else
      redirect_to error_not_found_path
    end
  end

  def person_entity_with_url(person_entity)
    person_entity.merge({
      url: person_path(id: person_entity[:username]),
      display_name: PersonViewUtils.person_entity_display_name(person_entity, @current_community.name_display_type)})
  end

  def paypal_process
    PaypalService::API::Api.process
  end

  private


  def bookingDatesValid?(start_on=nil, end_on=nil, listing_id=nil, start_on_old=nil, end_on_old=nil)
    start_on ||= params[:start_on]
    end_on ||= params[:end_on]
    listing_id ||= params[:listing_id]

    # If poolTool, then booking dates have to be present
    if params[:poolTool] == true || params[:action] == "update"
      if start_on == "" or end_on == ""
        return false
      end
    end

    # Only check the following things if start and end date are given
    if start_on && end_on && start_on != "" && end_on != ""
    # CHECK IF DATES ARE PLAUSIBLE
      if Date.parse(start_on) > Date.parse(end_on)
        return false
      end

    # PREVENT USER FROM CHANGING BOOKINGS IN THE PAST
      if (params[:poolTool] == true || params[:action] == "update") && !@current_user.is_allowed_to_book_in_past?
        # if this is an update and the booking is already in past
        if end_on_old && end_on_old < Date.today
          # User is not allowed to change anything (no description, date, ...)
          return false
        # if this is an update and the end date is in the future and the user tried to change the start date
        elsif start_on_old && start_on_old != Date.parse(start_on)
          # if start date is smaller than today
          if Date.parse(start_on) < Date.today
            return false
          end
        # if this is not an update
        elsif start_on_old == nil
          # if user tried to book in the past
          if Date.parse(start_on) < Date.today
            return false
          end
        end
      end

    # CHECK INTERSECTIONS WITH EXISTING BOOKING
      # Get all days of new booking
      if (start_on != end_on)
        new_booked_dates = (start_on..end_on).map(&:to_s)
      else
        new_booked_dates = [start_on]
      end

      # Get all booked dates from current listing which are saved in the db
      booked_dates = Listing.already_booked_dates(listing_id, @current_community)

      # Get all day of old booking if this is a booking change
      if (start_on_old and end_on_old)
        old_booked_dates = (start_on_old..end_on_old).map(&:to_s)

        # Remove those dates from the booked dates
        booked_dates = booked_dates - old_booked_dates
      end

      # Now check if days of new booking conflict with already booked days -> get Intersection of the 2 arrays
      intersection = new_booked_dates & booked_dates

      # If intersection of the two array isn't empty, then we have a booking conflict!
      return false if intersection != []
    end

    return true
  end


  def ensure_can_start_transactions(listing_model:, current_user:, current_community:, poolTool: false)
    error =
      if listing_model.closed?
        "layouts.notifications.you_cannot_reply_to_a_closed_offer"
      elsif !poolTool and listing_model.author == current_user
       "layouts.notifications.you_cannot_send_message_to_yourself"
      elsif !listing_model.visible_to?(current_user, current_community)
        "layouts.notifications.you_are_not_authorized_to_view_this_content"
      else
        nil
      end

    if error
      Result::Error.new(error, {error_tr_key: error})
    else
      Result::Success.new
    end
  end

  def after_create_flash(process:)
    case process[:process]
    when :none
      t("layouts.notifications.message_sent")
    else
      raise NotImplementedError.new("Not implemented for process #{process}")
    end
  end

  def after_create_redirect(process:, starter_id:, transaction:)
    case process[:process]
    when :none
      person_transaction_path(person_id: starter_id, id: transaction[:id])
    else
      raise NotImplementedError.new("Not implemented for process #{process}")
    end
  end

  def after_create_actions!(process:, transaction:, community_id:)
    case process[:process]
    when :none
      # TODO Do I really have to do the state transition here?
      # Shouldn't it be handled by the TransactionService
      MarketplaceService::Transaction::Command.transition_to(transaction[:id], "pending_free")

      # TODO: remove references to transaction model
      transaction = Transaction.find(transaction[:id])

      Delayed::Job.enqueue(MessageSentJob.new(transaction.conversation.messages.last.id, community_id))
    else
      raise NotImplementedError.new("Not implemented for process #{process}")
    end
  end
  # Fetch all related data based on the listing_id
  #
  # Returns: Result::Success([listing_id, listing_model, author, process, gateway])
  #
  def fetch_data(listing_id)
    Result.all(
      ->() {
        if listing_id.nil?
          Result::Error.new("No listing ID provided")
        else
          Result::Success.new(listing_id)
        end
      },
      ->(listing_id) {
        # TODO Do not use Models directly. The data should come from the APIs
        Maybe(@current_community.listings.where(id: listing_id).first)
          .map     { |listing_model| Result::Success.new(listing_model) }
          .or_else { Result::Error.new("Cannot find listing with id #{listing_id}") }
      },
      ->(_, listing_model) {
        # TODO Do not use Models directly. The data should come from the APIs
        Result::Success.new(listing_model.author)
      },
      ->(_, listing_model, *rest) {
        TransactionService::API::Api.processes.get(community_id: @current_community.id, process_id: listing_model.transaction_process_id)
      },
      ->(*) {
        Result::Success.new(MarketplaceService::Community::Query.payment_type(@current_community.id))
      },
    )
  end

  def validate_form(form_params, process)
    if process[:process] == :none && form_params[:message].blank?
      Result::Error.new("Message cannot be empty")
    else
      Result::Success.new
    end
  end

  def price_break_down_locals(tx)
    if tx[:payment_process] == :none && tx[:listing_price].cents == 0
      nil
    else
      unit_type = tx[:unit_type].present? ? ListingViewUtils.translate_unit(tx[:unit_type], tx[:unit_tr_key]) : nil
      localized_selector_label = tx[:unit_type].present? ? ListingViewUtils.translate_quantity(tx[:unit_type], tx[:unit_selector_tr_key]) : nil
      booking = !!tx[:booking]
      quantity = tx[:listing_quantity]
      show_subtotal = !!tx[:booking] || quantity.present? && quantity > 1 || tx[:shipping_price].present?
      total_label = (tx[:payment_process] != :preauthorize) ? t("transactions.price") : t("transactions.total")

      TransactionViewUtils.price_break_down_locals({
        listing_price: tx[:listing_price],
        localized_unit_type: unit_type,
        localized_selector_label: localized_selector_label,
        booking: booking,
        start_on: booking ? tx[:booking][:start_on] : nil,
        end_on: booking ? tx[:booking][:end_on] : nil,
        duration: booking ? tx[:booking][:duration] : nil,
        quantity: quantity,
        subtotal: show_subtotal ? tx[:listing_price] * quantity : nil,
        total: Maybe(tx[:payment_total]).or_else(tx[:checkout_total]),
        shipping_price: tx[:shipping_price],
        total_label: total_label
      })
    end
  end

  def render_free(listing_model:, author_model:, community:, params:)
    # TODO This data should come from API
    listing = {
      id: listing_model.id,
      title: listing_model.title,
      action_button_label: t(listing_model.action_button_tr_key),
    }
    author = {
      display_name: PersonViewUtils.person_display_name(author_model, community),
      username: author_model.username
    }

    unit_type = listing_model.unit_type.present? ? ListingViewUtils.translate_unit(listing_model.unit_type, listing_model.unit_tr_key) : nil
    localized_selector_label = listing_model.unit_type.present? ? ListingViewUtils.translate_quantity(listing_model.unit_type, listing_model.unit_selector_tr_key) : nil
    booking_start = Maybe(params)[:start_on].map { |d| TransactionViewUtils.parse_booking_date(d) }.or_else(nil)
    booking_end = Maybe(params)[:end_on].map { |d| TransactionViewUtils.parse_booking_date(d) }.or_else(nil)
    booking = !!(booking_start && booking_end)
    duration = booking ? DateUtils.duration_days(booking_start, booking_end) : nil
    quantity = Maybe(booking ? DateUtils.duration_days(booking_start, booking_end) : TransactionViewUtils.parse_quantity(params[:quantity])).or_else(1)
    total_label = t("transactions.price")

    m_price_break_down = Maybe(listing_model).select { |listing_model| listing_model.price.present? }.map { |listing_model|
      TransactionViewUtils.price_break_down_locals(
        {
          listing_price: listing_model.price,
          localized_unit_type: unit_type,
          localized_selector_label: localized_selector_label,
          booking: booking,
          start_on: booking_start,
          end_on: booking_end,
          duration: duration,
          quantity: quantity,
          subtotal: quantity != 1 ? listing_model.price * quantity : nil,
          total: listing_model.price * quantity,
          shipping_price: nil,
          total_label: total_label
        })
    }

    render "transactions/new", locals: {
             listing: listing,
             author: author,
             action_button_label: t(listing_model.action_button_tr_key),
             m_price_break_down: m_price_break_down,
             booking_start: booking_start,
             booking_end: booking_end,
             quantity: quantity,
             can_book_for_free: !FollowerRelationship.payment_necessary?(@listing_owner, @current_user.id),
             form_action: person_transactions_path(person_id: @current_user, listing_id: listing_model.id)
           }
  end

  def get_booking_to_edit
    # Get Booking from db
    @booking = Booking.where(:transaction_id => params[:id]).first
    @listing_owner = @booking.tx.author
  end

  def get_current_user_listing_owner_relation
    if @listing_owner.nil?
      # Get company listing which should be booked
      listing_owner_id = Listing.find(params[:listing_id]).author_id
      @listing_owner = Person.find(listing_owner_id)
    end

    # Get relation between listing owner and current user
    @relation = get_site_owner_visitor_relation(@listing_owner, @current_user)
  end

  def is_authorized_for_starting_transaction
    # If pool tool
    # The actions update & destroy are just for the pool tool
    if params[:poolTool]

      # People who can make Pool Tool transactions & changes
      if  @relation == :rentog_admin ||
          @relation == :company_admin_own_site ||
          @relation == :company_employee ||
          @relation == :trusted_company_admin ||
          @relation == :full_trusted_company_admin ||
          @relation == :trusted_company_employee ||
          @relation == :full_trusted_company_employee
            return true

      # others
      else
        flash[:error] = t("pool_tool.not_allowed__to_make_pool_tool_change")
        redirect_to root and return
      end
    end

    # untrusted employees can't make transactions
    if @relation == :untrusted_company_employee
      if !@current_community.employees_can_buy_listings
        unless @current_user.has_admin_rights_in?(@current_community)
          flash[:error] = t("transactions.employees_cannot_make_transactions")
          redirect_to root and return
        end
      end
    end

    # Unverified Company can't make transactions
    if @relation == :unverified_company
      flash[:error] = t("transactions.company_not_verified")
      redirect_to root and return
    end
  end

  def is_authorized_for_changing_pool_tool_booking
    transaction_starter = @booking.tx.starter

    # Ensure that only pool tool or free transactions of trusted users can be modified
    if @booking.tx.transaction_type == "extern" && !@booking.tx.status.include?("_free")
      error_message = "Access denied"

      respond_to do |format|
        format.json {render :json => { action: "update", status: "error", message: error_message } }
        format.html { redirect_to :root }
      end
      return
    end

    # Ensure that user can only verify his own or his employees bookings
      if @relation == :rentog_admin ||
         @relation == :company_admin_own_site ||
         @relation == :domain_supervisor
        # Rentog admin and Listing owner (Company admin) can modify all pool tool bookings

      elsif @current_user == transaction_starter
        # The starter of the transaction can modify his own booking

      elsif @current_user == transaction_starter.get_company
        # The company admin of the transaction starter can modify booking

      else
        # All others are not allowed to change bookings
        error_message = "Access denied"

        respond_to do |format|
          format.json { render :json => { action: "update", status: "error", message: error_message }}
          format.html { redirect_to :root }
        end
        return
      end
  end
end
