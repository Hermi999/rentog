module HomepageHelper
  def show_subcategory_list(category, current_category_id)
    category.id == current_category_id || category.children.any? do |child_category|
      child_category.id == current_category_id
    end
  end

  def with_first_listing_image(listing, &block)
    Maybe(listing)
      .listing_images
      .map { |images| images.first }[:small_3x2].each { |url|
      block.call(url)
    }
  end

  def without_listing_image(listing, &block)
    if listing.listing_images.size == 0
      block.call
    end
  end

  def post_listing_allowed
    # Only show button if,
    #   - no user is logged in AND not only pool tool is configured  OR
    #   - the logged in user is an organization  OR
    #   - a user is logged in AND employees also can create listings
    (@current_user.nil? && !Community.first.only_pool_tool) || (@current_user && @current_user.is_organization) || (@current_user && @current_community.employees_can_create_listings)
  end


  def get_listing_condition(listing)
    cust_field_val = Maybe(CustomFieldValue.where(listing_id: listing.id, custom_field_id: @condition_field_id).first).or_else(nil)
    sel_opt = cust_field_val.selected_options.first if cust_field_val
    if sel_opt
      title = sel_opt.title(I18n.locale)
      condition = sel_opt.title("de").downcase.to_sym
    end

    return {
      :title => title,
      :condition => condition
    }
  end

  def get_listing_shipment_to(listing)
    custom_field_value = CustomFieldValue.select("id").where(listing_id: listing.id, custom_field_id: @shipment_field_id).first
    val = custom_field_value.selected_options.map { |selected_option| selected_option.title(I18n.locale) }.join(", ") if custom_field_value

    unless val
      val = "n/a"
    end

    val
  end

  def get_price_options(listing)
    cust_field_val = Maybe(CustomFieldValue.where(listing_id: listing.id, custom_field_id: @price_options_field_id).first).or_else(nil)
    sel_opt = cust_field_val.selected_options.first if cust_field_val

    if sel_opt
      title = sel_opt.title(I18n.locale).remove(I18n.t("listings.form.price.price")).strip
      price_option = sel_opt.title("en").downcase
    end

    return {
      title: title,
      val: price_option
    }
  end
end
