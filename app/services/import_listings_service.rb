require 'roo'

class ImportListingsService
  attr_reader :valid_attributes, :invalid_attributes, :error_text, :listing_data, :invalid_rows

  def initialize(filepath, current_user)
    @invalid_rows = false
    @valid_attributes_from_db = getAllValidAttributes
    @mandatory_attributes_from_db = getAllMandatoryAttributes

    # Open the new file
    @import_file = Roo::Spreadsheet.open(filepath, extension: :xlsx)
    getValidAndInvalidAttributes

    # valid attributes found and all mandatory attributes are there
    if checkAttributeRequirements
      parse_args = {}
      @valid_attributes.each{ |_attr| parse_args[_attr[:name].to_sym] = _attr[:name] }
      @listing_data = @import_file.parse(parse_args)   # empty fields -> nil

      checkListingAttributeRequirements
      listingsToUpdate current_user
    end
  end

  def updateAndCreateListings
    updateListings
    createListings
  end

  def updateListings

  end

  def createListings
    listing_data.each_with_index do |_data, index|
      if index != 0 && _data[:invalid] == nil
        createListing _data
      end
    end
  end


  private

    def getAllValidAttributes
      _validAttr = [{name: "device_name"}, {name: "description"}, {name: "price"}]
      CustomFieldName.select('id, value, custom_field_id').where(locale: 'en').as_json.each do |_attr|
        _validAttr << {name: _attr["value"].split("(")[0].downcase.gsub(" ", "_"), custom_field_id: _attr["custom_field_id"].to_i}
      end
      _validAttr
    end

    def getAllMandatoryAttributes
      _mandAttr = [{name: "device_name"}]
      _validAttr = CustomFieldName.where(locale: 'en').each do |_attr|
        if _attr.custom_field.required
          _mandAttr << {name: _attr.value.split("(")[0].downcase.gsub(" ", "_"), custom_field_id: _attr.custom_field_id.to_i }
        end
      end
      _mandAttr
    end

    def getValidAndInvalidAttributes
      attributes = @import_file.sheet(0).row(1)
      @valid_attributes = []
      @valid_attributes_from_db.each{ |attr_from_db| @valid_attributes << attr_from_db if attributes.include? attr_from_db[:name]}

      _attr = []
      @valid_attributes.each {|x| _attr << x[:name]}
      @invalid_attributes = attributes - _attr
    end

    def checkAttributeRequirements
      if @valid_attributes == []
        @error_text = "No valid attributes found"
        return false
      elsif (@mandatory_attributes_from_db & @valid_attributes) != @mandatory_attributes_from_db
        missing_attr = @mandatory_attributes_from_db - (@mandatory_attributes_from_db & @valid_attributes)

        _attr_txt = ""
        missing_attr.each {|_attr| _attr_txt += _attr[:name] + ", "}
        @error_text = "Mandatory attributes #{_attr_txt[0..-3]} is/are missing"
        return false
      end

      return true
    end

    # each mandatory attribute has to be within each new/changed listing
    def checkListingAttributeRequirements
      @mandatory_attributes_from_db.each do |mand_attr|
        @listing_data.each do |listing|
          if listing[mand_attr[:name].to_sym] == nil
            listing[mand_attr[:name].to_sym] = "#mand_attr_missing"
            listing[:invalid] = "Mandatory attribute #{mand_attr[:name]} missing!"
            @invalid_rows = true
          end
        end
      end
    end

    # get listings, which have the same serial number and are already created on Rentog - Those will be updated, not newly created
    def listingsToUpdate(current_user)
      if @valid_attributes.any? {|x| x[:name] == "serial_number"}
        @listing_data.each_with_index do |listing, index|
          if listing[:serial_number] != nil && index > 0
            serial_custom_field_id = CustomFieldName.where("value like '%serial number%'")[0].custom_field_id

            old_listing = Maybe(CustomFieldValue.where(:custom_field_id => serial_custom_field_id, :text_value => listing[:serial_number])[0]).listing.or_else(nil)

            # check if listing belongs to users company
            next if old_listing == nil || (old_listing.author != current_user.get_company)
            listing[:update] = true
          end
        end
      end
    end

    def getListingAttributes

    end

    def setListingAttributes
    end

    # if listing with serial number is already in db, then update the existing listing
    def updateListing(listing_data)
    end

    # create a new listing based on the excel data
    def createListing(listing_data)
      listing_data.each do |attr|

        # wah: store subscribers and remove them from the params array
        subscribers = []
        if listing_data.subscribers
          listing_data.subscribers.each do |subscr|
            subscribers << Person.find(subscr) if subscr != ""
          end

          listing_data.delete("subscribers")
        end

        #shape = get_shape(Maybe(params)[:listing][:listing_shape_id].to_i.or_else(nil))
        shape =
          if listing_data.visibility
            ListingShape.get_shape_from_name(listing_data.visibility)
          else
            ListingShape.get_shape_from_name("intern")
          end

        # listing_params = ListingFormViewUtils.filter(params[:listing], shape)
        _unit_input = { type: "day",name_tr_key: null,kind: "time", selector_tr_key: null, quantity_selector: "day" }
        listing_unit = _unit_input.map { |u| ListingViewUtils::Unit.deserialize(u) }
        # listing_params = ListingFormViewUtils.filter_additional_shipping(listing_params, listing_unit)
        # validation_result = ListingFormViewUtils.validate(listing_params, shape, listing_unit)

        # unless validation_result.success
        #   flash[:error] = t("listings.error.something_went_wrong", error_code: validation_result.data.join(', '))
        #   return redirect_to new_listing_path
        # end

        listing_params = normalize_price_params(listing_params)
        m_unit = select_unit(listing_unit, shape)



        listing_params = listing_params.merge(
            community_id: @current_community.id,
            listing_shape_id: shape[:id],
            transaction_process_id: shape[:transaction_process_id],
            shape_name_tr_key: shape[:name_tr_key],
            action_button_tr_key: shape[:action_button_tr_key],
        ).merge(unit_to_listing_opts(m_unit)).except(:unit)

        @listing = Listing.new(listing_params)
        @listing.author = @current_user
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
    end

    def normalize_price_params(listing_params)
      currency = "EUR"
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
end
