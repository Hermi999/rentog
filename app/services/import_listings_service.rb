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
      @valid_attributes.each{ |x_attr| parse_args[x_attr[:name].to_sym] = x_attr[:name] }
      @listing_data = @import_file.parse(parse_args)   # empty fields -> nil

      checkListingAttributeRequirements
      listingsToUpdate current_user
    end
  end

  def updateAndCreateListings(current_user, current_community)
    result1 = updateListings(current_user, current_community)
    result2 = createListings(current_user, current_community)

    result1 + result2
  end

  def updateListings(current_user, current_community)
    result = []
    listing_data.each_with_index do |x_data, index|
      # only update if this listing is marked as "updateable"
      if index != 0 && x_data[:invalid] == nil && x_data[:update] == true
        result << updateListing(x_data, current_user, current_community)
      end
    end
    result
  end

  def createListings(current_user, current_community)
    result = []
    listing_data.each_with_index do |x_data, index|
      if index != 0 && x_data[:invalid] == nil && x_data[:update] == nil
        result << createListing(x_data, current_user, current_community)
      end
    end
    result
  end


  private

    def getAllValidAttributes
      x_validAttr = [{name: "device_name"}, {name: "description"}, {name: "price"}, {name: "visibility"}, {name: "device_closed"}]
      CustomFieldName.select('id, value, custom_field_id').where(locale: 'en').as_json.each do |x_attr|
        x_validAttr << {name: x_attr["value"].split("(")[0].downcase.gsub(" ", "_").chomp('_'), custom_field_id: x_attr["custom_field_id"].to_i}
      end
      x_validAttr << {name: "delete"}
      x_validAttr
    end

    def getAllMandatoryAttributes
      x_mandAttr = [{name: "device_name"}]
      x_validAttr = CustomFieldName.where(locale: 'en').each do |x_attr|
        if x_attr.custom_field.required
          x_mandAttr << {name: x_attr.value.split("(")[0].downcase.gsub(" ", "_").chomp('_'), custom_field_id: x_attr.custom_field_id.to_i }
        end
      end
      x_mandAttr
    end

    def getValidAndInvalidAttributes
      attributes = @import_file.sheet(0).row(1)
      @valid_attributes = []
      @valid_attributes_from_db.each{ |attr_from_db| @valid_attributes << attr_from_db if attributes.include? attr_from_db[:name]}

      x_attr = []
      @valid_attributes.each {|x| x_attr << x[:name]}
      @invalid_attributes = attributes - x_attr
    end

    def checkAttributeRequirements
      if @valid_attributes == []
        @error_text = "No valid attributes found"
        return false
      elsif (@mandatory_attributes_from_db & @valid_attributes) != @mandatory_attributes_from_db
        missing_attr = @mandatory_attributes_from_db - (@mandatory_attributes_from_db & @valid_attributes)

        x_attr_txt = ""
        missing_attr.each {|x_attr| x_attr_txt += x_attr[:name] + ", "}
        @error_text = "Mandatory attributes #{x_attr_txt[0..-3]} is/are missing"
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
      # if there exists an attribut name "serial_number"
      if @valid_attributes.any? {|x| x[:name] == "serial_number"}
        # go through each line (listing)
        @listing_data.each_with_index do |listing, index|
          if listing[:serial_number] != nil && index > 0
            serial_custom_field_id = CustomFieldName.where("value like '%serial number%'")[0].custom_field_id

            # all listings with this serial number
            old_listings = []
            name_of_first_dev = ""

            all_entries_with_this_serial_num = CustomFieldValue.where(:custom_field_id => serial_custom_field_id, :text_value => listing[:serial_number])
            all_entries_with_this_serial_num.each do |entry|
              # check if listing is not deleted, the title is the same and if the listing belongs to users company
              old_listing = entry.listing
              if old_listing && !old_listing.deleted && old_listing.title == listing[:device_name] && old_listing.author == current_user.get_company
                # listing is already marked as "update"...means that there are multiple entries in the excel file with the same title and serial
                if listing[:update] && listing[:invalid]
                    listing[:invalid][:msg] += ", " + listing[:device_name]
                elsif listing[:update]
                  listing[:invalid] = {type: "multiple_same_devices", msg: "There are more than 1 device with the same serial number registered for your company: "}
                  listing[:invalid][:msg] += name_of_first_dev + ", " + listing[:device_name]
                else
                  listing[:update] = true
                  listing[:listing_id] = old_listing.id
                  name_of_first_dev = listing[:device_name]
                end
              end
            end
          end
        end
      end
    end


    # if listing with serial number is already in db, then update the existing listing
    def updateListing(listing_data, current_user, current_community)
      listing_attributes = {}
      listing_attributes_custom_fields = {}
      listing = Listing.find(listing_data[:listing_id])

      # make sure that only valid attributes (which are in the db) are updated.
      # We store them into the "listing_attributes" and "listing_attributes_custom_fields"
      # arrays
      listing_data.each do |x_attr|
        case x_attr[0]
        when :delete
          # "delete" listing
          listing.update_attribute(:deleted, true)
          return listing.title
        when :device_name
          listing_attributes[:title] = x_attr[1]
        when :device_closed
          listing_attributes[:open] = (x_attr[1] == 0)
        when :visibility
          if x_attr[1].downcase == "intern" || x_attr[1].downcase == "trusted"
            listing_attributes[:availability] = x_attr[1].downcase
          end
        when :description, :price
          listing_attributes[x_attr[0]] = x_attr[1]
        else
          @valid_attributes_from_db.each do |valid_attr|
            if x_attr[0].to_s == valid_attr[:name]
              listing_attributes_custom_fields[valid_attr[:custom_field_id].to_s] = x_attr[1]
            end
          end
        end
      end

      # wah: store subscribers and remove them from the params array
      subscribers = []
      if listing_data[:subscribers]
        listing_data[:subscribers].each do |subscr|
          subscribers << Person.find(subscr) if subscr != ""
        end
      end

      shape_id = nil
      if listing_data[:visibility]
        shape_id = Maybe(ListingShape.get_shape_from_name(listing_data[:visibility])).id.or_else(nil)
      end
      if shape_id == nil
        shape_id = ListingShape.get_shape_from_name("private").id
      end
      shape = get_shape(shape_id.to_i,current_community)

      x_unit_input = { type: "day", name_tr_key: nil, kind: "time", selector_tr_key: nil, quantity_selector: "day" }
      listing_unit = x_unit_input

      listing_attributes = normalize_price_params(listing_attributes)
      m_unit = select_unit(listing_unit, shape)

      open_params = listing.closed? ? {open: true} : {}

      listing_attributes = listing_attributes.merge(
          transaction_process_id: shape[:transaction_process_id],
          shape_name_tr_key: shape[:name_tr_key],
          action_button_tr_key: shape[:action_button_tr_key],
          last_modified: DateTime.now
      ).merge(open_params).merge(unit_to_listing_opts(m_unit)).except(:unit)


      update_successful = listing.update_fields(listing_attributes)
      upsert_field_values!(listing, listing_attributes_custom_fields)

      if update_successful
        listing.subscribers = subscribers
        #listing.location.update_attributes(params[:location]) if @listing.location

        # wah - add this event to the events table
        ListingEvent.create({processor_id: current_user.id, listing_id: listing.id, event_name: "listing_updated"})

        Delayed::Job.enqueue(ListingUpdatedJob.new(listing.id, current_community.id))
        return listing.title
      else
        return listing.errors
      end
    end

    # create a new listing based on the excel data
    def createListing(listing_data, current_user, current_community)
      listing_attributes = {}
      listing_attributes_custom_fields = {}

      # make sure that only valid attributes (which are in the db) are created.
      # We store them into the "listing_attributes" and "listing_attributes_custom_fields"
      # arrays
      listing_data.each do |x_attr|
        case x_attr[0]
        when :device_name
          listing_attributes[:title] = x_attr[1]
        when :device_closed
          listing_attributes[:open] = (x_attr[1] == 0)
        when :visibility
          if x_attr[1].downcase == "intern" || x_attr[1].downcase == "trusted"
            listing_attributes[:availability] = x_attr[1].downcase
          end
        when :description, :price
          listing_attributes[x_attr[0]] = x_attr[1]
        else
          @valid_attributes_from_db.each do |valid_attr|
            if x_attr[0].to_s == valid_attr[:name]
              listing_attributes_custom_fields[valid_attr[:custom_field_id].to_s] = x_attr[1]
            end
          end
        end
      end

      # at the moment we just have one category ("default")
      listing_attributes[:category_id] = Category.first.id.to_s

      # wah: store subscribers and remove them from the params array
      subscribers = []
      if listing_data[:subscribers]
        listing_data[:subscribers].each do |subscr|
          subscribers << Person.find(subscr) if subscr != ""
        end
      end

      #shape = get_shape(Maybe(params)[:listing][:listing_shape_id].to_i.or_else(nil))
      shape_id = nil
      if listing_data[:visibility]
        shape_id = Maybe(ListingShape.get_shape_from_name(listing_data[:visibility])).id.or_else(nil)
      end
      if shape_id == nil
        shape_id = ListingShape.get_shape_from_name("private").id
      end
      shape = get_shape(shape_id.to_i,current_community)

      # listing_params = ListingFormViewUtils.filter(params[:listing], shape)
      x_unit_input = { type: "day", name_tr_key: nil, kind: "time", selector_tr_key: nil, quantity_selector: "day" }
      listing_unit = x_unit_input  #.map { |u| ListingViewUtils::Unit.deserialize(u) }
      # listing_params = ListingFormViewUtils.filter_additional_shipping(listing_params, listing_unit)
      # validation_result = ListingFormViewUtils.validate(listing_params, shape, listing_unit)

      # unless validation_result.success
      #   flash[:error] = t("listings.error.something_went_wrong", error_code: validation_result.data.join(', '))
      #   return redirect_to new_listing_path
      # end

      listing_attributes = normalize_price_params(listing_attributes)
      m_unit = select_unit(listing_unit, shape)


      listing_attributes = listing_attributes.merge(
          community_id: current_community.id,
          listing_shape_id: shape[:id],
          transaction_process_id: shape[:transaction_process_id],
          shape_name_tr_key: shape[:name_tr_key],
          action_button_tr_key: shape[:action_button_tr_key],
      ).merge(unit_to_listing_opts(m_unit)).except(:unit)

      listing = Listing.new(listing_attributes)
      listing.author = current_user
      listing.subscribers = subscribers if subscribers != []

      ActiveRecord::Base.transaction do
        if listing.save
          # wah - listing is saved even if attachment fails
          #save_listing_attachments(params)

          # wah - add this event to the events table
          ListingEvent.create({processor_id: current_user.id, listing_id: listing.id, event_name: "listing_created"})

          upsert_field_values!(listing, listing_attributes_custom_fields)

          #listing_image_ids =
          #  if params[:listing_images]
          #    params[:listing_images].collect { |h| h[:id] }.select { |id| id.present? }
          #  else
          #    logger.error("Listing images array is missing", nil, {params: params})
          #    []
          #  end

          #ListingImage.where(id: listing_image_ids, author_id: current_user.id).update_all(listing_id: listing.id)

          Delayed::Job.enqueue(ListingCreatedJob.new(listing.id, current_community.id))
          if current_community.follow_in_use?
            Delayed::Job.enqueue(NotifyFollowersJob.new(listing.id, current_community.id), :run_at => NotifyFollowersJob::DELAY.from_now)
          end

          return listing.title
        else
          return listing.errors
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

    def get_shape(listing_shape_id, current_community)
      shape_find_opts = {
        community_id: current_community.id,
        listing_shape_id: listing_shape_id
      }

      shape_res = ListingService::API::Api.shapes.get(shape_find_opts)

      if shape_res.success
        shape_res.data
      else
        raise ArgumentError.new(shape_res.error_msg) unless shape_res.success
      end
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

  def custom_field_value_factory(listing_id, custom_field_id, answer_value)
    question = CustomField.find(custom_field_id)

    answer = question.with_type do |question_type|
      case question_type
      when :dropdown
        option_id = nil
        if answer_value != ""
          text_val = "%" + answer_value.gsub("_", " ").gsub("\u2013", "-") + "%"
          option_id = Maybe(CustomFieldOptionTitle.where("value LIKE ?", text_val).first).custom_field_option_id.or_else(nil)
        end

        if option_id
          answer = DropdownFieldValue.new
          answer.custom_field_option_selections = [CustomFieldOptionSelection.new(:custom_field_value => answer, :custom_field_option_id => option_id)]
          answer
        else
          return nil
        end
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
        answer.date_value = answer_value.to_time.getutc
        answer
      else
        raise ArgumentError.new("Unimplemented custom field answer for question #{question_type}")
      end
    end

    answer.question = question
    answer.listing_id = listing_id
    return answer
  end
end
