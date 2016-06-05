class CustomFieldsPeopleController < ApplicationController
  before_filter :only => [ :update ] do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_view_this_content")
  end


  def update
    data = params[:values]

    person_id = data[(data.length-1).to_s][:person_id]

    if person_id.empty?
      company = @current_user.get_company
    else
      company = Person.find(person_id)
    end

    data.each_with_index do |element, index|
      # DoS protect: Limit how many custom fields a client can send
      break if index > 100

      already_there = false
      company.custom_fields.each do |custom_field|
        if custom_field.id == element[1]["id"].to_i
          already_there = true

          # Delete association
          if element[1]["value"] == "false"
            company.custom_fields.delete(custom_field)
          end
        end
      end

      # Add association
      if !already_there and element[1]["value"] == "true"
        company.custom_fields << CustomField.where(:id => element[1]["id"].to_i)
      end
    end

    respond_to do |format|
      format.json { render :json => {success: "success"} }
    end

  end


end
