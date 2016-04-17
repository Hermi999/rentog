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
    return_val = nil

    if @conditions[:all_selected_condition_field_options]
      @conditions[:all_selected_condition_field_options].each do |selected_condition_field_option|
        if selected_condition_field_option.listing_id == listing.id

          title = CustomFieldOption.find(selected_condition_field_option.custom_field_option_id).title(I18n.locale)

          case selected_condition_field_option.custom_field_option_id
            when @conditions[:condition_field_option_ids][:fabriksneu]
              return_val = {
                :condition => :fabriksneu,
                :title => title
              }
            when @conditions[:condition_field_option_ids][:neuwertig]
              return_val = {
                :condition => :neuwertig,
                :title => title
              }
            when @conditions[:condition_field_option_ids][:gut]
              return_val = {
                :condition => :gut,
                :title => title
              }
            when @conditions[:condition_field_option_ids][:gebraucht]
              return_val = {
                :condition => :gebraucht,
                :title => title
              }
            else
          end
        end
      end
    end

    return_val
  end
end
