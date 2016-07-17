# encoding: utf-8
class HomepageController < ApplicationController

  # Save current path, so that the user can be redirected if needed
  before_filter :save_current_path, :except => :sign_in

  APP_DEFAULT_VIEW_TYPE = "grid"
  VIEW_TYPES = ["grid", "list", "map", "wishlist"]


  def index
    cookies.permanent[:listings_mode] = "marketplace"

    # get the custom field ids of some listing attributes
    @condition_field_id = Maybe(CustomFieldName.where(:value => "Zustand").first).custom_field_id.to_i.or_else(nil)
    @shipment_field_id = Maybe(CustomFieldName.where(:value => "Shipment to").first).custom_field_id.to_i.or_else(nil)
    @price_options_field_id = Maybe(CustomFieldName.where(:value => "Price options").first).custom_field_id.to_i.or_else(nil)

    @wishlist_listings = Maybe(cookies[:wishlist]).split("&").or_else(nil)

    @homepage = true
    @restrictedMarketplace = params[:restrictedMarketplace]
    @marketplace_with_trusted_devs = params[:marketplace_with_trusted_devs]

    # Display list if on mobile device and no view selected
    if mobile_device? && params[:view].nil?
      params[:view] = "list"
    end

    @view_type = HomepageController.selected_view_type(params[:view], @current_community.default_browse_view, APP_DEFAULT_VIEW_TYPE, VIEW_TYPES)

    @categories = @current_community.categories.includes(:children)
    @main_categories = @categories.select { |c| c.parent_id == nil }

    all_shapes = shapes.get(community_id: @current_community.id)[:data]

    # This assumes that we don't never ever have communities with only 1 main share type and
    # only 1 sub share type, as that would make the listing type menu visible and it would look bit silly
    listing_shape_menu_enabled = all_shapes.size > 1
    @show_categories = @categories.size > 1
    show_price_filter = @current_community.show_price_filter && all_shapes.any? { |s| s[:price_enabled] }

    filters = @current_community.custom_fields.where(search_filter: true).sort
    @show_custom_fields = filters.present? || show_price_filter
    @category_menu_enabled = @show_categories || @show_custom_fields

    filter_params = {}

    listing_shape_param = params[:transaction_type]

    all_shapes = shapes.get(community_id: @current_community.id)[:data]
    selected_shape = all_shapes.find { |s| s[:name] == listing_shape_param }

    filter_params[:listing_shape] = Maybe(selected_shape)[:id].or_else(nil)

    compact_filter_params = HashUtils.compact(filter_params)

    per_page = @view_type == "map" ? APP_CONFIG.map_listings_limit : APP_CONFIG.grid_listings_limit

    includes =
      case @view_type
      when "grid"
        [:author, :listing_images]
      when "list"
        [:author, :listing_images, :num_of_reviews]
      when "map"
        [:author, :location]
      when "wishlist"
        [:author, :listing_images]
      else
        raise ArgumentError.new("Unknown view_type #{@view_type}")
      end

    if @view_type == "wishlist"
      wishlist_listing_ids = Maybe(cookies[:wishlist]).split("&").or_else([])
      search_result = find_listings_with_ids(includes, wishlist_listing_ids)
    else
      search_result = find_listings(params, per_page, compact_filter_params, includes.to_set)
    end

    shape_name_map = all_shapes.map { |s| [s[:id], s[:name]]}.to_h

    if request.xhr? # checks if AJAX request
      search_result.on_success { |listings|
        @listings = listings # TODO Remove

        # needed for reloading the next listings in the listing navigation
        if params[:getListingIds]
          cookies.permanent[:listings] = cookies[:listings].split("&") + listings.map(&:id)
          cookies.permanent[:current_page] = cookies.permanent[:current_page].to_i + 1

          respond_to do |format|
            format.json { render :json => {listing_ids: listings.map(&:id)} }
          end

        elsif @view_type == "grid" then
          cookies.permanent[:listings] = cookies[:listings].split("&") + listings.map(&:id)
          cookies.permanent[:current_page] = cookies.permanent[:current_page].to_i + 1
          render :partial => "grid_item", :collection => @listings, :as => :listing

        else
          cookies.permanent[:listings] = cookies[:listings].split("&") + listings.map(&:id)
          cookies.permanent[:current_page] = cookies.permanent[:current_page].to_i + 1
          render :partial => "list_item", :collection => @listings, :as => :listing, locals: { shape_name_map: shape_name_map, testimonials_in_use: @current_community.testimonials_in_use }
        end
      }.on_error {
        render nothing: true, status: 500
      }
    else
      main_search = (feature_enabled?(:location_search) && search_engine == :zappy) ? MarketplaceService::API::Api.configurations.get(community_id: @current_community.id).data[:main_search] : :keyword
      search_result.on_success { |listings|

        # wah: Store listings in cookie
        cookies.permanent[:count_listing_pages] = listings.total_pages
        cookies.permanent[:current_page] = 1
        cookies.permanent[:listings] = listings.map(&:id)
        if request.original_url.include?("transaction_type") ||
           request.original_url.include?("category") ||
           request.original_url.include?("price_min") ||
           request.original_url.include?("price_max") ||
           request.original_url.include?("&q=") ||
           request.original_url.include?("filter_option")
          cookies.permanent[:filter] = request.original_url
        else
          cookies.permanent[:filter] = ""
        end

        @listings = listings
        render locals: {
                 shapes: all_shapes,
                 filters: filters,
                 show_price_filter: show_price_filter,
                 selected_shape: selected_shape,
                 shape_name_map: shape_name_map,
                 testimonials_in_use: @current_community.testimonials_in_use,
                 listing_shape_menu_enabled: listing_shape_menu_enabled,
                 main_search: main_search }
      }.on_error { |e|
        flash[:error] = t("homepage.errors.search_engine_not_responding")
        @listings = Listing.none.paginate(:per_page => 1, :page => 1)
        render status: 500, locals: {
                 shapes: all_shapes,
                 filters: filters,
                 show_price_filter: show_price_filter,
                 selected_shape: selected_shape,
                 shape_name_map: shape_name_map,
                 testimonials_in_use: @current_community.testimonials_in_use,
                 listing_shape_menu_enabled: listing_shape_menu_enabled,
                 main_search: main_search }
      }
    end
  end


  # wah
  def load_custom_field_options
    custom_field_id = params[:custom_field_id]
    custom_field_options = []

    CustomFieldOption.where(custom_field_id: custom_field_id).order(:sort_priority).each do |option|
      custom_field_options << {
        title: option.title(I18n.locale),
        id: option.id
      }
    end

    respond_to do |format|
      format.json { render :json => {options: custom_field_options, field_id: custom_field_id, type: CustomField.where(id: custom_field_id).first.type} }
      format.html { redirect_to marketplace_path }
    end
  end


  def self.selected_view_type(view_param, community_default, app_default, all_types)
    if view_param.present? and all_types.include?(view_param)
      view_param
    elsif community_default.present? and all_types.include?(community_default)
      community_default
    else
      app_default
    end
  end

  private

  # Get all the listings for displaying them.
  # But only those which are not "visibility = intern"
  def find_listings(params, listings_per_page, filter_params, includes)
    Maybe(@current_community.categories.find_by_url_or_id(params[:category])).each do |category|
      filter_params[:categories] = category.own_and_subcategory_ids
      @selected_category = category
    end

    filter_params[:search] = params[:q] if params[:q]
    filter_params[:custom_dropdown_field_options] = HomepageController.dropdown_field_options_for_search(params)
    filter_params[:custom_checkbox_field_options] = HomepageController.checkbox_field_options_for_search(params)

    filter_params[:price_cents] = filter_range(params[:price_min], params[:price_max])

    p = HomepageController.numeric_filter_params(params)
    p = HomepageController.parse_numeric_filter_params(p)
    p = HomepageController.group_to_ranges(p)
    numeric_search_params = HomepageController.filter_unnecessary(p, @current_community.custom_numeric_fields)

    filter_params = filter_params.reject {
      |_, value| (value == "all" || value == ["all"])
    } # all means the filter doesn't need to be included

    checkboxes = filter_params[:custom_checkbox_field_options].map { |checkbox_field| checkbox_field.merge(type: :selection_group, operator: :and) }
    dropdowns = filter_params[:custom_dropdown_field_options].map { |dropdown_field| dropdown_field.merge(type: :selection_group, operator: :or) }
    numbers = numeric_search_params.map { |numeric| numeric.merge(type: :numeric_range) }

    # wah: restricted marketplace or open marketplace
    availability_for_sphinx = {}
    if @restrictedMarketplace
      availability = ["trusted", "all"]
      availability_for_sphinx[:availability_restricted_marketplace] = true

    elsif @marketplace_with_trusted_devs
      availability = ["intern", "trusted"]
      availability_for_sphinx[:availability_not_intern] = true
    else
      availability = ["all", nil]
      availability_for_sphinx[:availability_marketplace] = true
    end

    search = {
      # Add listing_id
      categories: filter_params[:categories],
      listing_shape_ids: Array(filter_params[:listing_shape]),
      price_cents: filter_params[:price_cents],
      keywords: filter_params[:search],
      fields: checkboxes.concat(dropdowns).concat(numbers),
      per_page: listings_per_page,
      page: Maybe(params)[:page].to_i.map { |n| n > 0 ? n : 1 }.or_else(1),
      price_min: params[:price_min],
      price_max: params[:price_max],
      locale: I18n.locale,
      include_closed: false,
      availability: availability,                                                 # wah_new
    }

    # wah: Add availability for sphinx search
    search.merge!(availability_for_sphinx)


    raise_errors = Rails.env.development?

    res = ListingIndexService::API::Api.listings.search(
      community_id: @current_community.id,
      search: search,
      includes: includes,
      engine: search_engine,
      raise_errors: raise_errors
      )

    # wah: Filter results based on marketplace type
    listings_restrictedMarketplace = []
    if @restrictedMarketplace
      # get all listings which should be shown - at the moment only external listings
      # remove comment from allowed_authors = ... to add also internal listings
      if @current_user  # if logged in, then show devices from followers.
        allowed_authors = @current_user.get_company.followers.as_json
        allowed_authors << @current_user.get_company.as_json
      else              # show devices from no one...
        allowed_authors = []
      end

      allowed_authors.each do |follower|
        res.data[:listings].each do |search_listing|
          if search_listing[:author][:id] == follower["id"]
            listings_restrictedMarketplace << search_listing
          end
        end
      end

     res.data[:listings] = listings_restrictedMarketplace
     res.data[:count] = listings_restrictedMarketplace.count
    else
    end

    pushBackListingsWithoutImage(res)

    res.and_then { |res|
      Result::Success.new(
        ListingIndexViewUtils.to_struct(
        result: res,
        includes: includes,
        page: search[:page],
        per_page: search[:per_page]
      ))
    }

  end

  # wah
  def find_listings_with_ids(includes, listing_ids)
    availability = ["all", nil]

    search = {
      listing_ids: listing_ids,
      locale: I18n.locale,
      include_closed: false,
      availability: availability,
      per_page: 100
    }

    raise_errors = Rails.env.development?


    res = ListingIndexService::API::Api.listings.search(
      community_id: @current_community.id,
      search: search,
      includes: includes.to_set,
      engine: search_engine,
      raise_errors: raise_errors
    )

    res.and_then { |res|
      Result::Success.new(
        ListingIndexViewUtils.to_struct(
        result: res,
        includes: includes,
        page: 1,
        per_page: 100
      ))
    }
  end

  # wah
  def pushBackListingsWithoutImage(res)
    with_image = []
    without_image = []

    res.data[:listings].each do |listing_data|
      if listing_data[:listing_images] && listing_data[:listing_images] != []
        with_image << listing_data
      else
        without_image << listing_data
      end
    end

    res.data[:listings] = with_image + without_image
  end


  def filter_range(price_min, price_max)
    if (price_min && price_max)
      min = MoneyUtil.parse_str_to_money(price_min, @current_community.default_currency).cents
      max = MoneyUtil.parse_str_to_money(price_max, @current_community.default_currency).cents

      if ((@current_community.price_filter_min..@current_community.price_filter_max) != (min..max))
        (min..max)
      else
        nil
      end
    end
  end

  # Return all params starting with `numeric_filter_`
  def self.numeric_filter_params(all_params)
    all_params.select { |key, value| key.start_with?("nf_") }
  end

  def self.parse_numeric_filter_params(numeric_params)
    numeric_params.inject([]) do |memo, numeric_param|
      key, value = numeric_param
      _, boundary, id = key.split("_")

      hash = {id: id.to_i}
      hash[boundary.to_sym] = value
      memo << hash
    end
  end

  def self.group_to_ranges(parsed_params)
    parsed_params
      .group_by { |param| param[:id] }
      .map do |key, values|
        boundaries = values.inject(:merge)

        {
          id: key,
          value: (boundaries[:min].to_f..boundaries[:max].to_f)
        }
      end
  end

  # Filter search params if their values equal min/max
  def self.filter_unnecessary(search_params, numeric_fields)
    search_params.reject do |search_param|
      numeric_field = numeric_fields.find(search_param[:id])
      search_param == { id: numeric_field.id, value: (numeric_field.min..numeric_field.max) }
    end
  end

  def self.options_from_params(params, regexp)
    option_ids = HashUtils.select_by_key_regexp(params, regexp).values

    array_for_search = CustomFieldOption.find(option_ids)
      .group_by { |option| option.custom_field_id }
      .map { |key, selected_options| {id: key, value: selected_options.collect(&:id) } }
  end

  def self.dropdown_field_options_for_search(params)
    options_from_params(params, /^filter_option/)
  end

  def self.checkbox_field_options_for_search(params)
    options_from_params(params, /^checkbox_filter_option/)
  end

  def shapes
    ListingService::API::Api.shapes
  end
end
