# rubocop:disable ClassLength
class ListingsController < ApplicationController
  class ListingDeleted < StandardError; end

  # Skip auth token check as current jQuery doesn't provide it automatically
  skip_before_filter :verify_authenticity_token, :only => [:close, :update, :follow, :unfollow]

  before_filter :only => [ :edit, :edit_form_content, :update, :close, :follow, :unfollow ] do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_view_this_content")
  end

  before_filter :only => [ :new, :new_form_content, :create ] do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_create_new_listing", :sign_up_link => view_context.link_to(t("layouts.notifications.create_one_here"), sign_up_path)).html_safe
  end

  before_filter :save_current_path, :only => :show
  before_filter :ensure_authorized_to_view, :only => [ :show, :follow, :unfollow ]

  before_filter :only => [ :close, :destroy ] do |controller|
    controller.ensure_current_user_is_listing_author t("layouts.notifications.only_listing_author_can_close_a_listing")
  end

  before_filter :only => [ :edit, :edit_form_content, :update ] do |controller|
    controller.ensure_current_user_is_listing_author t("layouts.notifications.only_listing_author_can_edit_a_listing")
  end

  before_filter :ensure_is_admin, :only => [ :move_to_top, :show_in_updates_email ]

  # If admin authorization is required to post. Also employees aren't allowed to post a new listing.
  before_filter :is_authorized_to_post, :only => [ :new, :create ]


  # wah: called when clicked on "show all listings" on profile page --> not working at the moment because I
  # separated the different listing types
  def index
    @selected_tribe_navi_tab = "home"

    respond_to do |format|
      # Keep format.html at top, as order is important for HTTP_ACCEPT headers with '*/*'
      format.html do
        if request.xhr? && params[:person_id] # AJAX request to load on person's listings for profile view
          @person = Person.find(params[:person_id])
          PersonViewUtils.ensure_person_belongs_to_community!(@person, @current_community)

          # Do not show internal listings if current logged in user is not ...
          if  !@relation == :company_employee &&              # not an employee of the company and
              !@relation == :rentog_admin &&                  # not the rentog admin and
              !@relation == :company_admin_own_site           # not the company admin himself
            availability = ["all", "trusted"]
          end

          # Returns the listings for one person formatted for profile page view
          per_page = params[:per_page] || 1000 # the point is to show all here by default
          includes = [:author, :listing_images]
          include_closed = @person == @current_user && params[:show_closed]

          search = {
            author_id: @person.id,
            include_closed: include_closed,
            page: 1,
            per_page: per_page,
            availability: availability
          }

          raise_errors = Rails.env.development?

          listings =
            ListingIndexService::API::Api
            .listings
            .search(
              community_id: @current_community.id,
              search: search,
              engine: search_engine,
              raise_errors: raise_errors,
              includes: includes
            ).and_then { |res|
            Result::Success.new(
              ListingIndexViewUtils.to_struct(
              result: res,
              includes: includes,
              page: search[:page],
              per_page: search[:per_page]
            ))
          }.data

          render :partial => "listings/profile_listings", :locals => {person: @person, limit: per_page, listings: listings}
        else
          redirect_to root
        end
      end

      format.atom do
        page =  params[:page] || 1
        per_page = params[:per_page] || 50

        all_shapes = get_shapes()
        all_processes = get_processes()
        direction_map = ListingShapeHelper.shape_direction_map(all_shapes, all_processes)

        if params[:share_type].present?
          direction = params[:share_type]
          params[:listing_shapes] =
            all_shapes.select { |shape|
              direction_map[shape[:id]] == direction
            }.map { |shape| shape[:id] }
        end
        raise_errors = Rails.env.development?

        search_res = if @current_community.private
                       Result::Success.new({count: 0, listings: []})
                     else
                       ListingIndexService::API::Api
                         .listings
                         .search(
                           community_id: @current_community.id,
                           search: {
                             listing_shape_ids: params[:listing_shapes],
                             page: page,
                             per_page: per_page
                           },
                           engine: search_engine,
                           raise_errors: raise_errors,
                           includes: [:listing_images, :author, :location])
                     end

        listings = search_res.data[:listings]

        title = build_title(params)
        updated = listings.first.present? ? listings.first[:updated_at] : Time.now

        render layout: false,
               locals: { listings: listings,
                         title: title,
                         updated: updated,

                         # deprecated
                         direction_map: direction_map
                       }
      end
    end
  end

  # for google maps view homepage
  def listing_bubble
    if params[:id]
      # get the listing condition id
      @condition_field_id = Maybe(CustomFieldName.where(:value => "Zustand").first).custom_field_id.to_i.or_else(nil)
      @restrictedMarketplace = request.referer.include?("restrictedMarketplace")

      @listing = Listing.find(params[:id])
      if @listing.visible_to?(@current_user, @current_community)
        render :partial => "homepage/listing_bubble", :locals => { :listing => @listing }
      else
        render :partial => "bubble_listing_not_visible"
      end
    end
  end

  # "2,3,4, 563" => [2, 3, 4, 563]
  def numbers_str_to_array(str)
    str.split(",").map { |num| num.to_i }
  end

  # Used to show multiple listings in one bubble for google maps view on homepage
  def listing_bubble_multiple
    # get the listing condition id
    @condition_field_id = Maybe(CustomFieldName.where(:value => "Zustand").first).custom_field_id.to_i.or_else(nil)
    @restrictedMarketplace = request.referer.include?("restrictedMarketplace")

    ids = numbers_str_to_array(params[:ids])

    if @current_user || !@current_community.private?
      @listings = @current_community.listings.where(listings: {id: ids}).order("listings.created_at DESC")
    else
      @listings = []
    end

    if @listings.size > 0
      render :partial => "homepage/listing_bubble_multiple"
    else
      render :partial => "bubble_listing_not_visible"
    end
  end

  # The listings page
  def show
    @selected_tribe_navi_tab = "home"

    # wah
    get_relation

    # redirect if intern listing
    if @listing.availability == "intern"      &&
       !@relation == :company_admin_own_site  &&
       !@relation == :rentog_admin            &&
       !@relation == :company_employee        &&
       !@relation == :domain_supervisor

        flash[:error] = t("transactions.listing_is_intern")
        redirect_to root and return
    end

    # wah: Get valid transactions in future, so that other user can not book the device
    #      if its already booked at a certain date
    @booked_dates = Listing.already_booked_dates_in_future(@listing.id, @current_community)


    @current_image = if params[:image]
      @listing.image_by_id(params[:image])
    else
      @listing.listing_images.first
    end

    @prev_image_id, @next_image_id = if @current_image
      @listing.prev_and_next_image_ids_by_id(@current_image.id)
    else
      [nil, nil]
    end

    payment_gateway = MarketplaceService::Community::Query.payment_type(@current_community.id)
    process = get_transaction_process(community_id: @current_community.id, transaction_process_id: @listing.transaction_process_id)


    rent_button = ""
    special_action_button_label = t(@listing.action_button_tr_key)
    show_price = true
    show_date = true

    case @relation
      when :rentog_admin
        show_price = true
        show_date = false
        rent_button = "pooltool"
        form_path = person_poolTool_path(@listing.author) + "?listing_id=" + @listing.id.to_s

      when :company_admin_own_site || :domain_supervisor
        rent_button = "pooltool"
        form_path = person_poolTool_path(@listing.author) + "?listing_id=" + @listing.id.to_s

      when :company_employee
        show_price = false
        show_date = false
        rent_button = "pooltool"
        form_path = person_poolTool_path(@listing.author) + "?listing_id=" + @listing.id.to_s

      when :full_trusted_company_employee
        show_price = @trusted_relation.payment_necessary
        show_date = false
        rent_button = "pooltool"
        form_path = person_poolTool_path(@listing.author) + "?listing_id=" + @listing.id.to_s

      when :trusted_company_employee
        form_path = new_transaction_path(listing_id: @listing.id)
        show_price = @trusted_relation.payment_necessary
        rent_button = "rent"
        form_path = new_transaction_path(listing_id: @listing.id)

      when :untrusted_company_employee
        if @current_community.employees_can_buy_listings
          form_path = new_transaction_path(listing_id: @listing.id)
        else
          form_path = new_person_person_message_path(@current_user.company)
          special_action_button_label = t("listings.show.request_by_company")
        end
        rent_button = "rent"

      when :full_trusted_company_admin
        show_price = @trusted_relation.payment_necessary
        show_date = false
        rent_button = "pooltool"
        form_path = person_poolTool_path(@listing.author) + "?listing_id=" + @listing.id.to_s

      when :trusted_company_admin
        show_price = @trusted_relation.payment_necessary
        rent_button = "rent"
        form_path = new_transaction_path(listing_id: @listing.id)

      when :untrusted_company_admin
        rent_button = "rent"
        form_path = new_transaction_path(listing_id: @listing.id)

      when :unverified_company
        flash.now[:error] = t("transactions.company_not_verified")

      when :logged_out_user
        rent_button = "rent"
        form_path = new_transaction_path(listing_id: @listing.id)

      else

    end

    community_country_code = LocalizationUtils.valid_country_code(@current_community.country)

    delivery_opts = delivery_config(@listing.require_shipping_address, @listing.pickup_enabled, @listing.shipping_price, @listing.shipping_price_additional, @listing.currency)

    received_testimonials = TestimonialViewUtils.received_testimonials_in_community(@listing.author, @current_community)
    received_positive_testimonials = TestimonialViewUtils.received_positive_testimonials_in_community(@listing.author, @current_community)
    feedback_positive_percentage = @listing.author.feedback_positive_percentage_in_community(@current_community)

    render locals: {
             form_path: form_path,
             payment_gateway: payment_gateway,
             # TODO I guess we should not need to know the process in order to show the listing
             process: process,
             delivery_opts: delivery_opts,
             listing_unit_type: @listing.unit_type,
             rent_button: rent_button,
             special_action_button_label: special_action_button_label,
             show_price: show_price,
             show_date: show_date,
             country_code: community_country_code,
             received_testimonials: received_testimonials,
             received_positive_testimonials: received_positive_testimonials,
             feedback_positive_percentage: feedback_positive_percentage
           }
  end

  def new
    # wah: NEW is also caling new_form_content (but edit is not calling edit_form_content)
    #initialize_user_plan_restrictions
    #initialize_user_plan_restrictions3

    get_relation
    @is_member_of_company = (@relation == :company_admin_own_site || @relation == :company_employee || @relation == :rentog_admin_own_site)

    category_tree = CategoryViewUtils.category_tree(
      categories: ListingService::API::Api.categories.get_all(community_id: @current_community.id)[:data],
      shapes: get_shapes,
      locale: I18n.locale,
      all_locales: @current_community.locales
    )

    render :new, locals: {
             categories: @current_community.top_level_categories,
             subcategories: @current_community.subcategories,
             shapes: get_shapes,
             category_tree: category_tree
           }
  end

  def new_form_content
    return redirect_to action: :new unless request.xhr?

    @listing = Listing.new
    @site_owner = Person.where(id: params[:person_id]).first || @current_user

    initialize_user_plan_restrictions
    return unless initialize_user_plan_restrictions2

    if (@current_user.location != nil)
      temp = @current_user.location
      @listing.build_origin_loc(temp.attributes)
    else
      @listing.build_origin_loc()
    end

    form_content
  end


  def edit_form_content
    return redirect_to action: :edit unless request.xhr?

    @site_owner = Person.where(id: params[:person_id]).first || @current_user

    initialize_user_plan_restrictions
    return unless initialize_user_plan_restrictions2

    if !@listing.origin_loc
        @listing.build_origin_loc()
    end

    form_content
  end


  def create
    # set listing author to site owner if admin or supervisor create listing
    get_relation
    if @relation == :rentog_admin || @relation == :domain_supervisor
      if !params[:listing][:person_id].empty?
        listing_author = Person.find(params[:listing][:person_id])
      end
    end

    @listing_author = listing_author || @current_user

    params[:listing].delete("person_id")  # this is only needed for creating a new device as an admin or supervisor
    params[:listing].delete("origin_loc_attributes") if params[:listing][:origin_loc_attributes][:address].blank?

    # wah: store subscribers and remove them from the params array
    subscribers = []
    if params[:listing][:subscribers]
      params[:listing][:subscribers].each do |subscr|
        subscribers << Person.find(subscr) if subscr != ""
      end

      params[:listing].delete("subscribers")
    end


    shape = get_shape(Maybe(params)[:listing][:listing_shape_id].to_i.or_else(nil))

    listing_params = ListingFormViewUtils.filter(params[:listing], shape)
    listing_unit = Maybe(params)[:listing][:unit].map { |u| ListingViewUtils::Unit.deserialize(u) }.or_else(nil)
    listing_params = ListingFormViewUtils.filter_additional_shipping(listing_params, listing_unit)
    validation_result = ListingFormViewUtils.validate(listing_params, shape, listing_unit)

    unless validation_result.success
      flash[:error] = t("listings.error.something_went_wrong", error_code: validation_result.data.join(', '))
      return redirect_to new_listing_path
    end


    listing_params = normalize_price_params(listing_params)
    m_unit = select_unit(listing_unit, shape)

    listing_params = create_listing_params(listing_params).merge(
        community_id: @current_community.id,
        listing_shape_id: shape[:id],
        transaction_process_id: shape[:transaction_process_id],
        shape_name_tr_key: shape[:name_tr_key],
        action_button_tr_key: shape[:action_button_tr_key],
    ).merge(unit_to_listing_opts(m_unit)).except(:unit)

    @listing = Listing.new(listing_params)
    @listing.author = @listing_author
    @listing.subscribers = subscribers if subscribers != []

    ActiveRecord::Base.transaction do
      if @listing.save
        # wah - listing is saved even if attachment fails
        save_listing_attachments(params)

        # wah - add this event to the events table
        ListingEvent.create({processor_id: @current_user.id, listing_id: @listing.id, event_name: "listing_created"})

        upsert_field_values!(@listing, params[:custom_fields])

        listing_image_ids =
          if params[:listing_images]
            params[:listing_images].collect { |h| h[:id] }.select { |id| id.present? }
          else
            logger.error("Listing images array is missing", nil, {params: params})
            []
          end

        ListingImage.where(id: listing_image_ids, author_id: @current_user.id).update_all(listing_id: @listing.id)

        Delayed::Job.enqueue(ListingCreatedJob.new(@listing.id, @current_community.id))
        if @current_community.follow_in_use?
          Delayed::Job.enqueue(NotifyFollowersJob.new(@listing.id, @current_community.id), :run_at => NotifyFollowersJob::DELAY.from_now)
        end

        flash[:notice] = t(
          "layouts.notifications.listing_created_successfully",
          :new_listing_link => view_context.link_to(t("layouts.notifications.create_new_listing"),new_listing_path)
        ).html_safe
        redirect_to @listing, status: 303 and return
      else
        logger.error("Errors in creating listing: #{@listing.errors.full_messages.inspect}")
        flash[:error] = t(
          "layouts.notifications.listing_could_not_be_saved",
          :contact_admin_link => view_context.link_to(t("layouts.notifications.contact_admin_link_text"), new_user_feedback_path, :class => "flash-error-link")
        ).html_safe
        redirect_to new_listing_path and return
      end
    end
  end

  def edit
    get_relation

    initialize_user_plan_restrictions
    initialize_user_plan_restrictions3

    @selected_tribe_navi_tab = "home"
    if !@listing.origin_loc
        @listing.build_origin_loc()
    end

    @custom_field_questions = @listing.category.custom_fields.where(community_id: @current_community.id) & @listing.listing_shape.custom_fields
    @numeric_field_ids = numeric_field_ids(@custom_field_questions)

    shape = select_shape(get_shapes, @listing.listing_shape_id)

    if shape
      @listing.listing_shape_id = shape[:id]
    end

    category_tree = CategoryViewUtils.category_tree(
      categories: ListingService::API::Api.categories.get_all(community_id: @current_community.id)[:data],
      shapes: get_shapes,
      locale: I18n.locale,
      all_locales: @current_community.locales
    )

    category_id, subcategory_id =
      if @listing.category.parent_id
        [@listing.category.parent_id, @listing.category.id]
      else
        [@listing.category.id, nil]
      end

    render locals: {
             category_tree: category_tree,
             categories: @current_community.top_level_categories,
             subcategories: @current_community.subcategories,
             shapes: get_shapes,
             category_id: category_id,
             subcategory_id: subcategory_id,
             shape_id: @listing.listing_shape_id,
             form_content: form_locals(shape)
           }
  end

  def update
    params[:listing].delete("person_id")  # this is only needed for creating a new device as an admin or supervisor

    # delete custom listing origin if user has cleared the field
    if (params[:listing][:origin] && (params[:listing][:origin_loc_attributes][:address].empty? || params[:listing][:origin].blank?))
      params[:listing].delete("origin_loc_attributes")
      if @listing.origin_loc
        @listing.origin_loc.delete
      end
    end

    # wah: store subscribers and remove them from the params array
    subscribers = []
    if params[:listing][:subscribers]
      params[:listing][:subscribers].each do |subscr|
        subscribers << Person.find(subscr) if subscr != ""
      end

      params[:listing].delete("subscribers")
    end

    shape = get_shape(params[:listing][:listing_shape_id])

    listing_params = ListingFormViewUtils.filter(params[:listing], shape)
    listing_unit = Maybe(params)[:listing][:unit].map { |u| ListingViewUtils::Unit.deserialize(u) }.or_else(nil)
    listing_params = ListingFormViewUtils.filter_additional_shipping(listing_params, listing_unit)
    validation_result = ListingFormViewUtils.validate(listing_params, shape, listing_unit)

    unless validation_result.success
      flash[:error] = t("listings.error.something_went_wrong", error_code: validation_result.data.join(', '))
      return redirect_to edit_listing_path
    end

    listing_params = normalize_price_params(listing_params)
    m_unit = select_unit(listing_unit, shape)

    open_params = @listing.closed? ? {open: true} : {}

    listing_params = create_listing_params(listing_params).merge(
      transaction_process_id: shape[:transaction_process_id],
      shape_name_tr_key: shape[:name_tr_key],
      action_button_tr_key: shape[:action_button_tr_key],
      last_modified: DateTime.now
    ).merge(open_params).merge(unit_to_listing_opts(m_unit)).except(:unit)

    # wah
    unless save_listing_attachments(params)
      redirect_to :back and return
    end

    update_successful = @listing.update_fields(listing_params)

    upsert_field_values!(@listing, params[:custom_fields])

    if update_successful
      @listing.subscribers = subscribers
      @listing.location.update_attributes(params[:location]) if @listing.location

      # wah - add this event to the events table
      ListingEvent.create({processor_id: @current_user.id, listing_id: @listing.id, event_name: "listing_updated"})

      flash[:notice] = t("layouts.notifications.listing_updated_successfully")
      Delayed::Job.enqueue(ListingUpdatedJob.new(@listing.id, @current_community.id))
      redirect_to @listing
    else
      logger.error("Errors in editing listing: #{@listing.errors.full_messages.inspect}")
      flash[:error] = t("layouts.notifications.listing_could_not_be_saved", :contact_admin_link => view_context.link_to(t("layouts.notifications.contact_admin_link_text"), new_user_feedback_path, :class => "flash-error-link")).html_safe
      redirect_to edit_listing_path(@listing)
    end
  end

  # wah: Delete pdf attachment
  def delete_attachment
    if params[:id]
      at = ListingAttachment.find(params[:id])
      if at.listing.author_id == @current_user.id
        at.delete
        at.save

        respond_to do |format|
          format.html { redirect_to :back }
          format.json { render :json => {status: "success"} }
        end
        return
      end
    end

    respond_to do |format|
      format.html { redirect_to :back }
      format.json { render :json => {status: "error"} }
    end
  end

  def close
    process = get_transaction_process(community_id: @current_community.id, transaction_process_id: @listing.transaction_process_id)

    payment_gateway = MarketplaceService::Community::Query.payment_type(@current_community.id)
    community_country_code = LocalizationUtils.valid_country_code(@current_community.country)

    @listing.update_attribute(:open, false)

    # wah - add this event to the events table
    ListingEvent.create({processor_id: @current_user.id, listing_id: @listing.id, event_name: "listing_closed"})

    respond_to do |format|
      format.html {
        redirect_to @listing
      }
      format.js {
        render :layout => false, locals: {payment_gateway: payment_gateway, process: process, country_code: community_country_code }
      }
    end
  end

  def destroy
    Listing.find(params[:id]).update_attribute(:deleted, true)
    redirect_to root and return
  end

  def move_to_top
    @listing = @current_community.listings.find(params[:id])

    # Listings are sorted by `sort_date`, so change it to now.
    if @listing.update_attribute(:sort_date, Time.now)
      redirect_to homepage_index_path
    else
      flash[:warning] = "An error occured while trying to move the listing to the top of the homepage"
      logger.error("An error occured while trying to move the listing (id=#{Maybe(@listing).id.or_else('No id available')}) to the top of the homepage")
      redirect_to @listing
    end
  end

  def show_in_updates_email
    @listing = @current_community.listings.find(params[:id])

    # Listings are sorted by `created_at`, so change it to now.
    if @listing.update_attribute(:updates_email_at, Time.now)
      render :nothing => true, :status => 200
    else
      logger.error("An error occured while trying to move the listing (id=#{Maybe(@listing).id.or_else('No id available')}) to the top of the homepage")
      render :nothing => true, :status => 500
    end
  end

  def ensure_current_user_is_listing_author(error_message)
    @listing = Listing.find(params[:id])
    return if current_user?(@listing.author) || @relation == :rentog_admin || @relation == :rentog_admin_own_site || @relation == :domain_supervisor
    flash[:error] = error_message
    redirect_to @listing and return
  end

  def follow
    change_follow_status("follow")
  end

  def unfollow
    change_follow_status("unfollow")
  end

  def verification_required

  end

  private

  def select_shape(shapes, id)
    if shapes.size == 1
      shapes.first
    else
      shapes.find { |shape| shape[:id] == id }
    end
  end

  def form_locals(shape)
    if shape
      process = get_transaction_process(community_id: @current_community.id, transaction_process_id: shape[:transaction_process_id])
      unit_options = ListingViewUtils.unit_options(shape[:units], unit_from_listing(@listing))

      shipping_price_additional =
        if @listing.shipping_price_additional
          @listing.shipping_price_additional.to_s
        elsif @listing.shipping_price
          @listing.shipping_price.to_s
        else
          0
        end

      community_country_code = LocalizationUtils.valid_country_code(@current_community.country)

      commission(@current_community, process).merge({
        shape: shape,
        unit_options: unit_options,
        shipping_price: Maybe(@listing).shipping_price.or_else(0).to_s,
        shipping_enabled: @listing.require_shipping_address?,
        pickup_enabled: @listing.pickup_enabled?,
        shipping_price_additional: shipping_price_additional,
        always_show_additional_shipping_price: shape[:units].length == 1 && shape[:units].first[:kind] == :quantity,
        paypal_fees_url: PaypalCountryHelper.fee_link(community_country_code)
      })
    else
      nil
    end
  end

  def form_content
    shape = get_shape(Maybe(params)[:listing_shape].to_i.or_else(nil))
    process = get_transaction_process(community_id: @current_community.id, transaction_process_id: shape[:transaction_process_id])

    # PaymentRegistrationGuard needs this to be set before posting
    @listing.transaction_process_id = shape[:transaction_process_id]
    @listing.listing_shape_id = shape[:id]

    # determine custom fields based on listing category and listing shape
    @listing.category = @current_community.categories.find(params[:subcategory].blank? ? params[:category] : params[:subcategory])
    @custom_field_questions = @listing.category.custom_fields & @listing.listing_shape.custom_fields
    @numeric_field_ids = numeric_field_ids(@custom_field_questions)

    payment_type = MarketplaceService::Community::Query.payment_type(@current_community.id)
    allow_posting, error_msg = payment_setup_status(
                     community: @current_community,
                     user: @current_user,
                     listing: @listing,
                     payment_type: payment_type,
                     process: process)

    if allow_posting
      render :partial => "listings/form/form_content", locals: form_locals(shape).merge(
               run_js_immediately: true
             )
    else
      render :partial => "listings/payout_registration_before_posting", locals: { error_msg: error_msg }
    end
  end

  def select_unit(listing_unit, shape)
    m_unit = Maybe(shape)[:units].map { |units|
      units.length == 1 ? units.first : units.find { |u| u == listing_unit }
    }
  end

  def unit_to_listing_opts(m_unit)
    m_unit.map { |unit|
      {
        unit_type: unit[:type],
        quantity_selector: unit[:quantity_selector],
        unit_tr_key: unit[:name_tr_key],
        unit_selector_tr_key: unit[:selector_tr_key]
      }
    }.or_else({
        unit_type: nil,
        quantity_selector: nil,
        unit_tr_key: nil,
        unit_selector_tr_key: nil
    })
  end

  def unit_from_listing(listing)
    HashUtils.compact({
      type: Maybe(listing.unit_type).to_sym.or_else(nil),
      quantity_selector: Maybe(listing.quantity_selector).to_sym.or_else(nil),
      unit_tr_key: listing.unit_tr_key,
      unit_selector_tr_key: listing.unit_selector_tr_key
    })
  end

  def build_title(params)
    category = Category.find_by_id(params["category"])
    category_label = (category.present? ? "(" + localized_category_label(category) + ")" : "")

    if ["request","offer"].include? params['share_type']
      listing_type_label = t("listings.index.#{params['share_type']+"s"}")
    else
      listing_type_label = t("listings.index.listings")
    end

    t("listings.index.feed_title",
      :optional_category => category_label,
      :community_name => @current_community.name_with_separator(I18n.locale),
      :listing_type => listing_type_label)
  end

  def commission(community, process)
    payment_type = MarketplaceService::Community::Query.payment_type(community.id)
    payment_settings = TransactionService::API::Api.settings.get_active(community_id: community.id).maybe
    currency = community.default_currency

    case [payment_type, process]
    when matches([__, :none])
      {seller_commission_in_use: false,
       payment_gateway: nil,
       minimum_commission: Money.new(0, currency),
       commission_from_seller: 0,
       minimum_price_cents: 0}
    when matches([:paypal])
      p_set = Maybe(payment_settings_api.get_active(community_id: community.id))
        .select {|res| res[:success]}
        .map {|res| res[:data]}
        .or_else({})

      {seller_commission_in_use: payment_settings[:commission_type].or_else(:none) != :none,
       payment_gateway: payment_type,
       minimum_commission: Money.new(p_set[:minimum_transaction_fee_cents], currency),
       commission_from_seller: p_set[:commission_from_seller],
       minimum_price_cents: p_set[:minimum_price_cents]}
    else
      {seller_commission_in_use: !!community.commission_from_seller,
       payment_gateway: payment_type,
       minimum_commission: Money.new(0, currency),
       commission_from_seller: community.commission_from_seller,
       minimum_price_cents: community.absolute_minimum_price(currency).cents}
    end
  end

  def paypal_minimum_commissions_api
    PaypalService::API::Api.minimum_commissions_api
  end

  def payment_settings_api
    TransactionService::API::Api.settings
  end

  # Ensure that only users with appropriate visibility settings can view the listing
  def ensure_authorized_to_view
    # If listing is not found (in this community) the find method
    # will throw ActiveRecord::NotFound exception, which is handled
    # correctly in production environment (404 page)
    @listing = @current_community.listings.find(params[:id])

    raise ListingDeleted if @listing.deleted?

    unless @listing.visible_to?(@current_user, @current_community) || @relation == :rentog_admin
      if @current_user
        if @listing.closed?
          flash[:error] = t("layouts.notifications.listing_closed")
        else
          flash[:error] = t("layouts.notifications.you_are_not_authorized_to_view_this_content")
        end
        redirect_to marketplace_path and return
      else
        session[:return_to] = request.fullpath
        flash[:warning] = t("layouts.notifications.you_must_log_in_to_view_this_content")
        redirect_to login_path and return
      end
    end
  end

  def change_follow_status(status)
    status.eql?("follow") ? @current_user.follow(@listing) : @current_user.unfollow(@listing)
    respond_to do |format|
      format.html {
        redirect_to @listing
      }
      format.js {
        render :follow, :layout => false
      }
    end
  end

  def custom_field_value_factory(listing_id, custom_field_id, answer_value)
    question = CustomField.find(custom_field_id)

    answer = question.with_type do |question_type|
      case question_type
      when :dropdown
        option_id = answer_value.to_i
        answer = DropdownFieldValue.new
        answer.custom_field_option_selections = [CustomFieldOptionSelection.new(:custom_field_value => answer, :custom_field_option_id => answer_value)]
        answer
      when :text
        answer = TextFieldValue.new
        answer.text_value = answer_value
        answer
      when :numeric
        answer = NumericFieldValue.new
        answer.numeric_value = ParamsService.parse_float(answer_value)
        answer
      when :checkbox
        answer = CheckboxFieldValue.new
        answer.custom_field_option_selections = answer_value.map { |value| CustomFieldOptionSelection.new(:custom_field_value => answer, :custom_field_option_id => value) }
        answer
      when :date_field
        answer = DateFieldValue.new
        answer.date_value = Time.utc(answer_value["(1i)"].to_i,
                                     answer_value["(2i)"].to_i,
                                     answer_value["(3i)"].to_i)
        answer
      else
        raise ArgumentError.new("Unimplemented custom field answer for question #{question_type}")
      end
    end

    answer.question = question
    answer.listing_id = listing_id
    return answer
  end

  # Note! Requires that parent listing is already saved to DB. We
  # don't use association to link to listing but directly connect to
  # listing_id.
  def upsert_field_values!(listing, custom_field_params)
    custom_field_params ||= {}

    # Delete all existing
    custom_field_value_ids = listing.custom_field_values.map(&:id)
    CustomFieldOptionSelection.where(custom_field_value_id: custom_field_value_ids).delete_all
    CustomFieldValue.where(id: custom_field_value_ids).delete_all

    field_values = custom_field_params.map do |custom_field_id, answer_value|
      custom_field_value_factory(listing.id, custom_field_id, answer_value) unless is_answer_value_blank(answer_value)
    end.compact

    # Insert new custom fields in a single transaction
    CustomFieldValue.transaction do
      field_values.each(&:save!)
    end
  end

  def is_answer_value_blank(value)
    if value.kind_of?(Hash)
      value["(3i)"].blank? || value["(2i)"].blank? || value["(1i)"].blank?  # DateFieldValue check
    else
      value.blank?
    end
  end

  def is_authorized_to_post
    # employee can't create listings
    if @current_user && !@current_user.is_organization
      if !@current_community.employees_can_create_listings
        unless @relation == :rentog_admin
          flash[:error] = t("listings.error.employees_do_not_post")
          redirect_to marketplace_path and return
        end
      end
    end

    # admin-verification is needed for companies
    if @current_community.require_verification_to_post_listings?
      unless @relation == :rentog_admin || @current_community_membership.can_post_listings?
        redirect_to verification_required_listings_path
      end
    end
  end

  def numeric_field_ids(custom_fields)
    custom_fields.map do |custom_field|
      custom_field.with(:numeric) do
        custom_field.id
      end
    end.compact
  end

  def normalize_price_params(listing_params)
    currency = listing_params[:currency]
    listing_params.inject({}) do |hash, (k, v)|
      case k
      when "price"
        hash.merge(:price_cents =>  MoneyUtil.parse_str_to_subunits(v, currency))
      when "shipping_price"
        hash.merge(:shipping_price_cents =>  MoneyUtil.parse_str_to_subunits(v, currency))
      when "shipping_price_additional"
        hash.merge(:shipping_price_additional_cents =>  MoneyUtil.parse_str_to_subunits(v, currency))
      else
        hash.merge( k.to_sym => v )
      end
    end
  end

  def payment_setup_status(community:, user:, listing:, payment_type:, process:)
    case [payment_type, process]
    when matches([nil]),
         matches([__, :none])
      [true, ""]
    when matches([:braintree])
      can_post = !PaymentRegistrationGuard.new(community, user, listing).requires_registration_before_posting?
      settings_link = payment_settings_path(community.payment_gateway.gateway_type, user)
      error_msg = t("listings.new.you_need_to_fill_payout_details_before_accepting", :payment_settings_link => view_context.link_to(t("listings.new.payment_settings_link"), settings_link)).html_safe

      [can_post, error_msg]
    when matches([:paypal])
      can_post = PaypalHelper.community_ready_for_payments?(community.id)
      error_msg =
        if user.has_admin_rights_in?(community)
          t("listings.new.community_not_configured_for_payments_admin",
            payment_settings_link: view_context.link_to(
              t("listings.new.payment_settings_link"),
              admin_paypal_preferences_path()))
            .html_safe
        else
          t("listings.new.community_not_configured_for_payments",
            contact_admin_link: view_context.link_to(
              t("listings.new.contact_admin_link_text"),
              new_user_feedback_path))
            .html_safe
        end
      [can_post, error_msg]
    else
      [true, ""]
    end
  end

  def delivery_config(require_shipping_address, pickup_enabled, shipping_price, shipping_price_additional, currency)
    shipping = delivery_price_hash(:shipping, shipping_price, shipping_price_additional)
    pickup = delivery_price_hash(:pickup, Money.new(0, currency), Money.new(0, currency))

    case [require_shipping_address, pickup_enabled]
    when matches([true, true])
      [shipping, pickup]
    when matches([true, false])
      [shipping]
    when matches([false, true])
      [pickup]
    else
      []
    end
  end

  def create_listing_params(params)
    listing_params = params.except(:delivery_methods).merge(
      require_shipping_address: Maybe(params[:delivery_methods]).map { |d| d.include?("shipping") }.or_else(false),
      pickup_enabled: Maybe(params[:delivery_methods]).map { |d| d.include?("pickup") }.or_else(false),
      price_cents: params[:price_cents],
      shipping_price_cents: params[:shipping_price_cents],
      shipping_price_additional_cents: params[:shipping_price_additional_cents],
      currency: params[:currency]
    )

    add_location_params(listing_params, params)
  end

  def add_location_params(listing_params, params)
    if params[:origin_loc_attributes].nil?
      listing_params
    else
      location_params = params[:origin_loc_attributes].permit(
        :address,
        :google_address,
        :latitude,
        :longitude,
        :location_alias
      ).merge(
        location_type: :origin_loc
      )

      listing_params.merge(
        origin_loc_attributes: location_params
      )
    end
  end

  def get_transaction_process(community_id:, transaction_process_id:)
    opts = {
      process_id: transaction_process_id,
      community_id: community_id
    }

    TransactionService::API::Api.processes.get(opts)
      .maybe[:process]
      .or_else(nil)
      .tap { |process|
        raise ArgumentError.new("Cannot find transaction process: #{opts}") if process.nil?
      }
  end

  def listings_api
    ListingService::API::Api
  end

  def transactions_api
    TransactionService::API::Api
  end

  def valid_unit_type?(shape:, unit_type:)
    if unit_type.nil?
      shape[:units].empty?
    else
      shape[:units].any? { |unit| unit[:type] == unit_type.to_sym }
    end
  end

  def get_shapes
    @shapes ||= listings_api.shapes.get(community_id: @current_community.id).maybe.or_else(nil).tap { |shapes|
      raise ArgumentError.new("Cannot find any listing shape for community #{@current_community.id}") if shapes.nil?
    }
  end

  def get_processes
    @processes ||= transactions_api.processes.get(community_id: @current_community.id).maybe.or_else(nil).tap { |processes|
      raise ArgumentError.new("Cannot find any transaction process for community #{@current_community.id}") if processes.nil?
    }
  end

  def get_shape(listing_shape_id)
    shape_find_opts = {
      community_id: @current_community.id,
      listing_shape_id: listing_shape_id
    }

    shape_res = listings_api.shapes.get(shape_find_opts)

    if shape_res.success
      shape_res.data
    else
      raise ArgumentError.new(shape_res.error_msg) unless shape_res.success
    end
  end

  def delivery_price_hash(delivery_type, price, shipping_price_additional)
      { name: delivery_type,
        price: price,
        shipping_price_additional: shipping_price_additional,
        price_info: ListingViewUtils.shipping_info(delivery_type, price, shipping_price_additional),
        default: true
      }
  end

  def save_listing_attachments(params)
    return true if params[:attachment].nil?

    # wah: Store & Remove attachment from params hash
    listing_attachments = params[:attachment][:file]

    listing_attachments.each_with_index do |attachm, index|
      # only 20 attachments at once
      if index > 20
        break
      elsif @listing.valid?
        # wah: Create new attachment object
        @attachment = ListingAttachment.new
        @attachment.attachment = attachm
        @attachment.author_id = Maybe(@listing.author).id.or_else(nil) || @listing_author.id
        @attachment.listing_id = @listing.id

        if @attachment.save
          # wah: Add attachment to listing
          @listing.listing_attachments << @attachment
        else
          if @attachment.errors && @attachment.errors.first[0] != :attachment_content_type
            if @attachment.errors.first[0] == :max_upload_limit
              flash[:error] = t("layouts.notifications.listing_attachment_max_upload_limit").html_safe
            elsif @attachment.errors.first[0] == :user_tried_to_hack_user_plan
              flash[:error] = t("layouts.notifications.listing_attachment_userplan_error", link: get_wp_url("pricing")).html_safe
            else
              flash[:error] = @attachment.errors.first[1]
            end
          else
            flash[:error] = t("layouts.notifications.listing_attachment_error")
          end

          return false
        end
      end
    end
    return true
  end


  # Listing attachment & custom fields restrictions
  def initialize_user_plan_restrictions
     # wah
    if @listing && @listing.id
      listing_id = @listing.id
    else
      listing_id = -1
    end

    userplanservice = UserPlanService::Api.new
    @max_attachments = userplanservice.get_plan_feature_level(@current_user, :listing_attachments)[:value]
    listingAttachmentsCount = ListingAttachment.where(author_id: @current_user.id, listing_id: listing_id).count
    @attachments_left = listingAttachmentsCount < @max_attachments

    # wah - user plan: max listing optional attributes
    if params["edit_custom_fields"]
      @max_listing_optional_attributes = userplanservice.get_plan_feature_level(@current_user, :listing_optional_attributes)[:value]
      listingOptionalAttributesCount = @current_user.custom_fields.count
      @maxOptionalAttributesLeft = @max_listing_optional_attributes <= listingOptionalAttributesCount
    end
  end

  def initialize_user_plan_restrictions2
    # wah - user plan: non marketplace listings restriction
    # Only if user want to create a private listing
    userplanservice = UserPlanService::Api.new
    listing_shape_name =
      if ListingShape.where(id: params["listing_shape"]).first
        ListingShape.where(id: params["listing_shape"]).first.get_standardized_listingshape_name
      else
        "private"
      end

    if listing_shape_name == "private"
      @max_nonMarketlistings = userplanservice.get_plan_feature_level(@current_user, :company_non_market_listings)[:value]
      nonMarketlistingCount = Listing.where("author_id = ? And (availability = 'trusted' Or availability = 'intern')", @current_user.id).count
      if @max_nonMarketlistings <= nonMarketlistingCount && params["edit_custom_fields"].nil?
        render :partial => "listings/form/max_company_non_market_listings" and return false
      end
    end

    return true
  end

  def initialize_user_plan_restrictions3
    # wah - user plan: non marketplace listings restriction
    # Only if user want to create a private listing
    userplanservice = UserPlanService::Api.new
    listing_shape_name =
      if ListingShape.where(id: params["listing_shape"]).first
        ListingShape.where(id: params["listing_shape"]).first.get_standardized_listingshape_name
      else
        "private"
      end

    if listing_shape_name == "private"
      @max_nonMarketlistings = userplanservice.get_plan_feature_level(@current_user, :company_non_market_listings)[:value]
      nonMarketlistingCount = Listing.where("author_id = ? And (availability = 'trusted' Or availability = 'intern')", @current_user.id).count
      @nonMarketlistings_left = @max_nonMarketlistings > nonMarketlistingCount
    end
  end

  # wah
  # overwrite site_owner & relation because for the listing we can also get this information directly from the listing
  def get_relation
    @site_owner = Maybe(@listing).author.or_else(nil) || Person.where(id: params[:person_id]).first || @current_user
    @relation = get_site_owner_visitor_relation(@site_owner, @current_user)
  end
end
