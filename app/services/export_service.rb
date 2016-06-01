require 'axlsx'

class ExportService
  def initialize(current_user, path_to_file, start_date, end_date)
    # check if dir exists
    dir = File.dirname(path_to_file)
    FileUtils.mkdir_p(dir) unless File.directory?(dir)

    # delete oldest file if there are more than 10000 files
    all_files = Dir.entries(dir)
    if all_files.count > 10000
      all_files.sort_by! { |file| File.mtime(dir + "/" + file) }

      all_files.each do |file|
        if file != "." and file != ".."
          File.delete(dir + "/" + file) if File.exist?(dir + "/" + file)
          break
        end
      end
    end

    # get data from db
    company_members = current_user.get_company_members
    devices = Listing.where(author_id: current_user.get_company.id, deleted: false)
    valid_listing_attributes = getAllValidAttributes
    transactions = Transaction.where(listing_author_id: current_user.get_company.id, deleted: false)

    # create new export file
    @p = Axlsx::Package.new
    @wb = @p.workbook


    # worksheet devices
    @wb.add_worksheet(:name => "Devices") do |sheet|
      listing_headers = []
      valid_listing_attributes.each {|_attr| listing_headers << _attr[:name]}

      sheet.add_row listing_headers

      devices.each do |dev|
        _internal_id = dev.author.get_company.organization_name + "_dev_" + (11982 + dev.id).to_s
        _visibility = Maybe(dev.get_listing_type).or_else("error")
        _visibility = _visibility.slice(0,1).capitalize + _visibility.slice(1..-1)
        _price = dev.price_cents.to_f / 100
        _loc = Maybe(dev.location).address.or_else(nil)
        _loc_alias = Maybe(dev.location).location_alias.or_else(nil)
        _row = [_internal_id, dev.title, !dev.open, dev.author.organization_name, dev.description, _price, _visibility, _loc, _loc_alias, dev.created_at, dev.updated_at]

        # go through each valid listing attribute and each custom field of the listing
        # if the listing has no custom field for a valid listing attribute then fill in a blank
        valid_listing_attributes.each do |_attr|
          if _attr[:custom_field_id]
            _val = ""
            dev.custom_field_values.each do |custom_field|
              if _attr[:custom_field_id] == custom_field.custom_field_id
                if custom_field.class.to_s == "DropdownFieldValue" || custom_field.class.to_s == "CheckboxFieldValue"
                  custom_field.custom_field_option_selections.each do |option_selection|
                    _val += ", " if _val != ""
                    _val += option_selection.custom_field_option.titles.where(locale: I18n.locale).first.value if option_selection.custom_field_option
                  end
                else
                  _val = custom_field.text_value || custom_field.numeric_value || custom_field.date_value
                end

                break
              end
            end
            _row << _val
          end
        end

        sheet.add_row _row
      end
    end


    # worksheet bookings
    @wb.add_worksheet(:name => "Bookings") do |sheet|
      sheet.add_row ["internal_device_id", "device_name", "device_owner", "renter", "reason", "start_on", "end_on", "booking_description", "device_location", "device_location_alias", "booking_created_on", "booking_last_changed"]

      transactions.each do |b|
        if b.listing

          # wah: not good. Change transactions query to a join:   Transaction.joins(:listing, :booking, :starter).select("").where("")
          if b.booking.end_on > start_date && b.booking.start_on < end_date
            _internal_device_id = b.seller.get_company.organization_name + "_dev_" + (11982 + b.listing_id).to_s
            _dev_owner = b.seller.get_company.organization_name
            _renter = b.starter.given_name + " " + b.starter.family_name  if b.starter.is_employee?
            _renter = b.starter.organization_name                         if b.starter.is_organization
            _loc_alias = Maybe(b.starter.location).location_alias.or_else(nil)
            _loc = Maybe(b.starter.location).address.or_else(nil)
            _booking_created_at = b.booking.created_at
            _booking_updated_at = b.booking.updated_at

            sheet.add_row [_internal_device_id, b.listing.title, _dev_owner, _renter, b.booking.reason, I18n.l(b.booking.start_on), I18n.l(b.booking.end_on), b.booking.description, _loc, _loc_alias, _booking_created_at, _booking_updated_at]
          end
        end
      end
    end



    # worksheet people
    @wb.add_worksheet(:name => "People") do |sheet|
      sheet.add_row ["first_name", "last_name", "email", "location", "location_alias", "phone_number", "description", "role", "trusts/follows", "trusted_by/followed_by"]

      company_members.each do |member|
        role =
          if member.is_employee?
            "Pool Tool User"
          else
            "Pool Tool Admin"
          end
        _loc = Maybe(member.location).address.or_else(nil)
        _loc_alias = Maybe(member.location).location_alias.or_else(nil)
        _followers = member.followers.pluck(:organization_name).join(", ") if member.followers != []
        _followed  = member.followed_people.pluck(:organization_name).join(", ") if member.followed_people != []
        sheet.add_row [member.given_name, member.family_name, member.emails.first.address, _loc, _loc_alias, member.phone_number, member.description, role, _followed, _followers]
      end
    end



    # save file
    @p.serialize(path_to_file)


  end

  def get_listing_export(start_date, end_date)
  end

  def getAllValidAttributes
    _validAttr = [{name: "internal_id"}, {name: "device_name"}, {name: "device_closed"}, {name: "device_owner"}, {name: "description"}, {name: "price"}, {name: "visibility"}, {name: "location"}, {name: "location_alias"}, {name: "device_create_at"}, {name: "device_last_changed"}]
    CustomFieldName.select('id, value, custom_field_id').where(locale: 'en').as_json.each do |_attr|
      _attr_name = _attr["value"].split("(")[0].downcase.gsub(" ", "_").chomp('_')
      _validAttr << {name: _attr_name, custom_field_id: _attr["custom_field_id"].to_i}
    end
    _validAttr
  end
end
