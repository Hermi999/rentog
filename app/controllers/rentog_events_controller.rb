class RentogEventsController < ApplicationController

  before_filter :ensure_is_authorized_to_view, only: [:index, :export]

  def index
    if params[:zero_entries]
      db_filter = "event_result = 0 AND event_name = 'marketplace_search_or_filter'"
    elsif params[:only_marketplace_search]
      db_filter = "event_name = 'marketplace_search_or_filter'"
    else
      db_filter = ""
    end

    @current_page = params[:page] || 1
    @rentog_events = RentogEvent.where(db_filter).paginate(:page => @current_page, :per_page => @per_page).order('created_at DESC')
    @per_page = 15


    get_events_as_string_array
  end

  def export
    @rentog_events = RentogEvent.all.order('created_at DESC').limit(10000)
    get_events_as_string_array

    # create new export file
    @p = Axlsx::Package.new
    @wb = @p.workbook

    # worksheet devices
    @wb.add_worksheet(:name => "Rentog Events") do |sheet|
      sheet.add_row RentogEvent.new.attributes.keys

      @table.each do |row|
        new_row = row.map do |field|
          if field.class.to_s == "Hash"
            field[:name].to_s + ", " + field[:email].to_s+ ", " + field[:phone].to_s
          else
            field.to_s.gsub("<br>", "\r\n").gsub(/<(.*?)>/, "")
          end
        end

        sheet.add_row new_row
      end
    end

    file_name = 'rentog_events.xlsx'
    path_to_file = "#{Rails.root}/public/system/exportfiles/" + file_name

    @p.serialize(path_to_file)
    send_file(path_to_file, filename: file_name, type: "application/vnd.ms-excel")
  end


  private

    def ensure_is_authorized_to_view
      # ALLOWED
        return if @relation == :rentog_admin

      # NOT ALLOWED
        # with error message
        flash[:error] = "not allowed"
        redirect_to root
        return false
    end

    def get_events_as_string_array
      @table = []
      event_type = nil

      @rentog_events.each_with_index do |lr, index|
      row = []

      lr.attributes.each do |attr_values|
        if attr_values[0] == "visitor_id" && attr_values[1] && attr_values[1] != ""
          visitor_ = Visitor.find(attr_values[1])
          row << {name: visitor_.name, href: "#", email: visitor_.email, phone: visitor_.phone}

        elsif attr_values[0] == "person_id" && attr_values[1] && attr_values[1] != ""
          person_ = Person.find(attr_values[1])
          row << {name: person_.full_name, href: person_path(person_), email: person_.emails.last.address, phone: person_.phone_number}

        elsif attr_values[0] == "event_name"
          if attr_values[1] == "marketplace_search_or_filter"
            event_type = "marketplace_search_or_filter"
          end

          row << Maybe(attr_values[1]).or_else("-----")

        elsif attr_values[0] == "event_details"
          if event_type == "marketplace_search_or_filter"
            filter_params = eval(attr_values[1])
            res = ""
            filter_params.each do |filter_|
              if filter_[1] != nil && filter_[1] != []

                if filter_[0].to_s == "price_cents"
                  res += ("<br><b>Price:</b> " + (filter_[1].to_a[0]/100).to_s + " - " + (filter_[1].to_a[-1]/100).to_s).html_safe

                elsif filter_[0].to_s == "custom_dropdown_field_options" || filter_[0].to_s == "custom_checkbox_field_options"
                  filter_[1].each do |val|
                    res += "<br><b>" + CustomFieldName.where(custom_field_id: val[:id], locale: "de").first.value + ": </b>"
                    val[:value].each do |val_|
                      res += CustomFieldOption.find(val_).title + ", "
                    end
                  end

                elsif filter_[0].to_s == "categories"
                  res += "<br><b>" + filter_[0].to_s + ":</b> "
                  filter_[1].each do |category_id|
                    res += Category.find(category_id).translations.where(locale: "en").first.name
                  end

                else
                  res += "<br><b>" + filter_[0].to_s + "</b>: " + filter_[1].to_s
                end
              end
            end

            row << Maybe(res).or_else("---------") #.gsub("<br>", "/n").gsub(/<(.*?)>/, "")

          else
            row << Maybe(attr_values[1]).or_else("---")
          end

        else
          row << Maybe(attr_values[1]).or_else("---")
        end
      end

      @table << row
    end
  end
end
