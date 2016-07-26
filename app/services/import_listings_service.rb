require 'roo'

class ImportListingsService
  attr_reader :valid_attributes, :invalid_attributes, :error_text, :listing_data, :invalid_rows

  # get valid and mandatory listing attributes
  # open the new file and get valid and invalid Attributes
  # 
  def initialize(filepath, current_user, relation)

    # Open the new file & get the attributes row from it
    @relation = relation
    @import_file = Roo::Spreadsheet.open(filepath, extension: :xlsx)
    @excel_attributes_raw = @import_file.sheet(0).row(1)
    @excel_attributes = @excel_attributes_raw.map{ |el| el.downcase.gsub(" ", "_") }

    # validate attributes row
    @invalid_rows = false
    @valid_attributes_from_db = getAllValidAttributes
    @mandatory_attributes_from_db = getAllMandatoryAttributes(current_user)
    
    # get valid and invalid attributes based on name
    getValidAndInvalidAttributes

    # valid attributes found and all mandatory attributes are there
    if checkAttributeRequirements
      # get valid listings from excel
      getValidListingsFromExcel

      # handle title and shipment to countries
      handleTitle
      handleCountries
      handleUSPs

      # check if there exists a value for mandatory attributes
      checkListingAttributeRequirements

      # handle listings which have to be updated
      listingsToUpdate current_user
    end
  end

  def updateAndCreateListings(current_user, current_community, relation)
    result1 = updateListings(current_user, current_community, relation)
    result2 = createListings(current_user, current_community, relation)

    result1 + result2
  end

  def updateListings(current_user, current_community, relation)
    result = []
    @listing_data.each_with_index do |x_data, index|
      # only update if this listing is marked as "updateable"
      if index != 0 && x_data[:invalid] == nil && x_data[:update] == true
        result << updateListing(x_data, current_user, current_community, relation)
      end
    end
    result
  end

  def createListings(current_user, current_community, relation)
    result = []
    @listing_data.each_with_index do |x_data, index|
      if index != 0 && x_data[:invalid] == nil && x_data[:update] == nil
        result << createListing(x_data, current_user, current_community, relation)
      end
    end
    result
  end


  private

    def getAllValidAttributes
      x_validAttr = [{name: "username"}, {name: "device_name"}, {name: "main_category"}, {name: "sub_category"}, {name: "pool_id"}, {name: "description"}, {name: "price"}, {name: "type"}, {name: "device_closed"}, {name: "subscriber_emails"}, {name: "unique_selling_propositions"}]
      custom_field_names = CustomFieldName.select('id, value, custom_field_id').where(locale: 'en').as_json

      custom_field_names.each do |x_attr|
        x_validAttr << {name: x_attr["value"].split("(")[0].downcase.gsub(" ", "_").chomp('_'), custom_field_id: x_attr["custom_field_id"].to_i}
      end
      x_validAttr << {name: "delete"}
      x_validAttr
    end

    def getAllMandatoryAttributes(current_user)
      x_mandAttr = [{name: "type"}, {name: "device_name"}]
      x_mandAttr << {name: "pool_id"} if current_user.is_supervisor?

      x_validAttr = CustomFieldName.where(locale: 'en').each do |x_attr|
        if Maybe(x_attr.custom_field).required.or_else(false)
          x_mandAttr << {name: x_attr.value.split("(")[0].downcase.gsub(" ", "_").chomp('_'), custom_field_id: x_attr.custom_field_id.to_i }
        end
      end
      x_mandAttr
    end

    # get valid and invalit attributes based on the name
    def getValidAndInvalidAttributes
      @valid_attributes = []

      @valid_attributes_from_db.each_with_index do |attr_from_db, i| 
        if @excel_attributes.include? attr_from_db[:name]
          @valid_attributes << attr_from_db
        end
      end

      x_attr = []
      @valid_attributes.each {|x| x_attr << x[:name]}
      @invalid_attributes = @excel_attributes - x_attr
    end

    # get valid listings from excel
    def getValidListingsFromExcel
      # get all values the rows below the attribute row
      parse_args = {}
      @excel_attributes_raw.each{ |x_attr| parse_args[x_attr.to_sym] = x_attr }
      @listing_data = @import_file.parse(parse_args)

      # transform excel data
      data = []
      @listing_data.each_with_index do |row, j| 
        data << {}

        row.each do |field|
          if j == 0
          data[j][field[0].to_s.downcase.gsub(" ", "_").to_sym] = field[1].downcase.gsub(" ", "_")
          else
            if field[1].class.to_s == "String"
              da = field[1].gsub("<html>", "").gsub("</html>", "")
            else
              da = field[1]
            end
            data[j][field[0].to_s.downcase.gsub(" ", "_").to_sym] = da
          end
        end
      end
      @listing_data = data

      # delete columns which are not valid
      @listing_data[0].each_with_index do |header_row_element, index|
        unless @valid_attributes.map{|el| el[:name]}.include?(header_row_element[1])
          @listing_data.each_with_index do |data_rows, ii|
            data_rows.delete(header_row_element[0]) if ii > 0
          end
          @listing_data[0].delete(header_row_element[0])
        end
      end
    end

    def handleTitle
      @listing_data.each_with_index do |row, i|
        if i > 0
          if row[:device_name] == "" || row[:type].downcase == "sell" || row[:type].downcase == "rent"
            @listing_data[i][:device_name] = row[:model] + " (" + row[:manufacturer] + ")"
          end
        end
      end
    end

    def handleCountries
      @listing_data.each_with_index do |row, i|
        if i > 0
          if row[:shipment_to].downcase == "eu"
            eu_countries = []
            ISO3166::Country.find_all_by("eu_member", true).each do |country_|
              eu_countries << country_[1]["translations"]["en"]
            end

            @listing_data[i][:shipment_to] = eu_countries.join(", ")

          elsif row[:shipment_to].downcase.gsub(" ", "") == "worldwide"
            @listing_data[i][:shipment_to] = ISO3166::Country.all_translated('EN').join(", ")
          end
        end
      end
    end

    def handleUSPs
      @listing_data.each_with_index do |row, i|
        if row[:unique_selling_propositions] 
          if row[:unique_selling_propositions] != ""
            if i == 0
              @listing_data[i].delete(:unique_selling_propositions)
              @listing_data[i][:unique_selling_proposition1] = "unique_selling_proposition1"
              @listing_data[i][:unique_selling_proposition2] = "unique_selling_proposition2"
              @listing_data[i][:unique_selling_proposition3] = "unique_selling_proposition3"
              
            else
              usps = row[:unique_selling_propositions].split("**")
              @listing_data[i][:unique_selling_proposition_1] = Maybe(usps[1]).strip.or_else(nil)
              @listing_data[i][:unique_selling_proposition_2] = Maybe(usps[2]).strip.or_else(nil)
              @listing_data[i][:unique_selling_proposition_3] = Maybe(usps[3]).strip.or_else(nil)
              @listing_data[i].delete(:unique_selling_propositions)

              usp1 = CustomFieldName.where(value: "Unique Selling Proposition 1", locale: "en").last.custom_field_id
              usp2 = CustomFieldName.where(value: "Unique Selling Proposition 2", locale: "en").last.custom_field_id
              usp3 = CustomFieldName.where(value: "Unique Selling Proposition 3", locale: "en").last.custom_field_id

              @valid_attributes << {name: :unique_selling_proposition_1, custom_field_id: usp1}
              @valid_attributes << {name: :unique_selling_proposition_2, custom_field_id: usp2}
              @valid_attributes << {name: :unique_selling_proposition_3, custom_field_id: usp3}
              @valid_attributes.each_with_index { |attr, index| @valid_attributes.delete_at(index) if attr[:name] == :unique_selling_proposition }

            end
          elsif
            @listing_data[i].delete(:unique_selling_propositions)
          end
        else
          @listing_data[i].delete(:unique_selling_propositions)
        end
      end
    end

    # check if the requirements for the attributes are fullfilled: 
    # All mandatory are there and there are valid attributes.
    def checkAttributeRequirements
      if @valid_attributes.empty?
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

          # handle title
          if listing[:type] == "renting"
          end
        end
      end
    end

    # get listings, which have the same hidden upload id and are already created on Rentog - Those will be updated, not newly created
    def listingsToUpdate(current_user)
      # if there exists an attribut name "hidden_upload_id"
      if @valid_attributes.any? {|x| x[:name] == "hidden_upload_id"}
        # go through each line (listing)
        @listing_data.each_with_index do |listing, index|
          if listing[:hidden_upload_id] != nil && index > 0
            # get new listing owner
            person = 
              if listing[:username] && @relation == :rentog_admin
                Person.where(username: listing[:username]).last || current_user
              else
                current_user
              end

            hidden_upload_custom_field_id = CustomFieldName.where("value like '%hidden upload id%'")[0].custom_field_id

            # all listings with this hidden upload id
            old_listings = []
            name_of_first_dev = ""

            all_entries_with_this_upload_id_num = CustomFieldValue.where(:custom_field_id => hidden_upload_custom_field_id, :text_value => listing[:hidden_upload_id])
            all_entries_with_this_upload_id_num.each do |entry|
              # check if listing is not deleted, the title is the same and if the listing belongs to users company or the supervisors domain
              old_listing = entry.listing
              if old_listing && !old_listing.deleted && 
                 old_listing.title == listing[:device_name] && 
                  (old_listing.author == person.get_company || 
                  current_user.is_supervisor_of?(old_listing.author) && old_listing.author.username == listing[:pool_id])

                # listing is already marked as "update"...means that there are multiple entries in the excel file with the same title and hidden upload id
                if listing[:update] && listing[:invalid]
                    listing[:invalid][:msg] += ", " + listing[:device_name]
                elsif listing[:update]
                  listing[:invalid] = {type: "multiple_same_devices", msg: "There are more than 1 device with the same hidden upload id registered for your company: "}
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


    # if listing with hidden upload id is already in db, then update the existing listing
    def updateListing(listing_data, current_user, current_community, relation)
      listing_attributes = {}
      listing_attributes_custom_fields = {}
      subscribers = []
      listing = Listing.find(listing_data[:listing_id])

      # remove username of author. Only needed for creating listings. The Admin can update listings of 
      # others by just giving the correct listing id
      listing_data.delete(:username)

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
        
        when :pool_id
          # no need for this one here...listings is uniquely identified via listing_id
        
        when :main_category
          listing_attributes[:main_category] = CategoryTranslation.where(name: x_attr[1]).last
 
        when :sub_category
          listing_attributes[:sub_category] = CategoryTranslation.where(name: x_attr[1])

        when :subscriber_emails
          x_attr[1].split(",").each do |subscr|
            p = Maybe(Email.where(address: subscr.strip).first).person.or_else(nil)
            if p.is_employee_of?(listing.author_id) || p == listing.author
              subscribers << p
            end
          end
        
        when :device_closed
          listing_attributes[:open] = (x_attr[1] == 0)
        
        when :type
          if x_attr[1].downcase == "intern" || x_attr[1].downcase == "trusted"
            listing_attributes[:availability] = x_attr[1].downcase
          end
        
        when :description, :price
          listing_attributes[x_attr[0]] = x_attr[1]
        
        else
          @valid_attributes_from_db.each do |valid_attr|
            if x_attr[0].to_s == valid_attr[:name]
              type = Maybe(CustomField.where(id: valid_attr[:custom_field_id]).last).type.or_else(nil)
              
              if type == "CheckboxField" && x_attr[1]
                listing_attributes_custom_fields[valid_attr[:custom_field_id].to_s] = []

                x_attr[1] = x_attr[1].split(",").map(&:strip).each do |val|
                  optionTitle = CustomFieldOptionTitle.where(value: val).last
                  option = optionTitle.custom_field_option if optionTitle
                  if option && option.custom_field_id == valid_attr[:custom_field_id]
                    listing_attributes_custom_fields[valid_attr[:custom_field_id].to_s] << option.id
                  end
                end
              
              else
                listing_attributes_custom_fields[valid_attr[:custom_field_id].to_s] = x_attr[1]
              end
            end
          end
        end
      end

      # get the correct sub category
      if listing_attributes[:main_category] || listing_attributes[:sub_category]
        listing_attributes[:sub_category].each do |sub_cat|
          if sub_cat.category.parent == listing_attributes[:main_category].category
            listing_attributes[:category_id] = sub_cat.category_id.to_s
          end
        end
      else
        listing_attributes[:category_id] = nil
      end  
      listing_attributes.delete(:main_category)
      listing_attributes.delete(:sub_category)


      shape_id = nil
      if listing_data[:type]
        shape_id = Maybe(ListingShape.get_shape_from_name(listing_data[:type])).id.or_else(nil)
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
        listing.subscribers = listing.subscribers | subscribers.compact
        #listing.location.update_attributes(params[:location]) if @listing.location

        # wah - add this event to the events table
        ListingEvent.create({person_id: current_user.id, listing_id: listing.id, event_name: "listing_updated"})

        Delayed::Job.enqueue(ListingUpdatedJob.new(listing.id, current_community.id))
        return listing.title
      else
        return listing.errors
      end
    end

    # create a new listing based on the excel data
    def createListing(listing_data, current_user, current_community, relation)
      listing_attributes = {}
      listing_attributes_custom_fields = {}
      subscribers = []
      author_username = nil

      # check if pool id (author username) is given, if this is the supervisor
      if relation == :domain_supervisor
        unless listing_data[:pool_id]
          return {title: listing_attributes[:title], message: "Listings does no have the mandatory attribute 'pool_id'"}
        else
          author_username = listing_data[:pool_id]
        end
      elsif relation == :rentog_admin && listing_data[:username]
        author_username = listing_data[:username]
      end

      listing_author = Person.where(username: author_username).first || current_user
      listing_data.delete(:username)

      # make sure that only valid attributes (which are in the db) are created.
      # We store them into the "listing_attributes" and "listing_attributes_custom_fields"
      # arrays
      listing_data.each do |x_attr|
        case x_attr[0]
        when :device_name
          listing_attributes[:title] = x_attr[1]
        
        when :pool_id
          # already done above
        
        when :subscriber_emails
          x_attr[1].split(",").each do |subscr|
            p = Maybe(Email.where(address: subscr.strip).first).person.or_else(nil)
            if p && (p.is_employee_of?(listing_author.id) || p == listing_author)
              subscribers << p
            end
          end

        when :main_category
          listing_attributes[:main_category] = CategoryTranslation.where(name: x_attr[1]).last

        when :sub_category
          listing_attributes[:sub_category] = CategoryTranslation.where(name: x_attr[1])

        when :device_closed
          listing_attributes[:open] = (x_attr[1] == 0)

        when :type
          if x_attr[1].downcase == "intern" || x_attr[1].downcase == "trusted"
            listing_attributes[:availability] = x_attr[1].downcase
          end

        when :description, :price
          listing_attributes[x_attr[0]] = x_attr[1]

        else
          @valid_attributes_from_db.each do |valid_attr|
            if x_attr[0].to_s == valid_attr[:name]
              type = Maybe(CustomField.where(id: valid_attr[:custom_field_id]).last).type.or_else(nil)
              if type == "CheckboxField" && x_attr[1]
                listing_attributes_custom_fields[valid_attr[:custom_field_id].to_s] = []

                x_attr[1] = x_attr[1].split(",").map(&:strip).each do |val|
                  optionTitle = CustomFieldOptionTitle.where(value: val).last
                  
                  option = optionTitle.custom_field_option if optionTitle
                  if option && option.custom_field_id == valid_attr[:custom_field_id]
                    listing_attributes_custom_fields[valid_attr[:custom_field_id].to_s] << option.id
                  end

                end
              else
                listing_attributes_custom_fields[valid_attr[:custom_field_id].to_s] = x_attr[1]
              end
            end
          end
        end
      end

      # get the correct sub category
      if listing_attributes[:main_category] && listing_attributes[:sub_category]
        listing_attributes[:sub_category].each do |sub_cat|
          if sub_cat.category.parent == listing_attributes[:main_category].category
            listing_attributes[:category_id] = sub_cat.category_id.to_s
          end
        end
      else
        listing_attributes[:category_id] = nil
      end  
      listing_attributes.delete(:main_category)
      listing_attributes.delete(:sub_category)

      #shape = get_shape(Maybe(params)[:listing][:listing_shape_id].to_i.or_else(nil))
      shape_id = nil
      if listing_data[:type]
        shape_id = Maybe(ListingShape.get_shape_from_name(listing_data[:type])).id.or_else(nil)
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
      listing.author = listing_author
      listing.subscribers = subscribers.compact if subscribers.compact.any?

      ActiveRecord::Base.transaction do
        if listing.save
          # wah - listing is saved even if attachment fails
          #save_listing_attachments(params)

          # wah - add this event to the events table
          ListingEvent.create({person_id: current_user.id, listing_id: listing.id, event_name: "listing_created"})

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
          possible_option_titles = CustomFieldOptionTitle.where("value LIKE ?", text_val)
          
          if possible_option_titles
            possible_option_titles.each do |opt_tit|
              if Maybe(opt_tit.custom_field_option).custom_field_id.or_else(false) == custom_field_id.to_i
                option_id = opt_tit.custom_field_option_id
                break
              end
            end
          end
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
