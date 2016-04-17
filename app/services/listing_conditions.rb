class ListingConditions
  def self.get_listing_conditions
    all_selected_condition_field_options = nil
    condition_field_option_ids = nil
    condition_fields = CustomFieldName.where(:value => "Zustand")

    if condition_fields != []
      condition_field_id = condition_fields.first.custom_field_id.to_i
      condition_field_options = CustomFieldOption.where(:custom_field_id => condition_field_id)

      # Get All the selected condition field options of all listings
      # We especially need the 'listing id' and the 'option id' so that we know
      # in what kind of kondition each listing is
      all_selected_condition_field_options = CustomFieldOption.joins(:custom_field_option_selections, :custom_field_values)
                                                               .select("custom_field_options.custom_field_id,
                                                                        custom_field_option_selections.custom_field_value_id,
                                                                        custom_field_option_selections.custom_field_option_id,
                                                                        custom_field_values.listing_id")
                                                               .where(:custom_field_id => 9)


      # Get the different contition field option ids
      condition_field_option_ids = get_condition_field_option_ids(condition_field_options)
    else
      return {
        all_selected_condition_field_options: all_selected_condition_field_options,
        condition_field_option_ids: condition_field_option_ids
      }
    end
  end



  private

    # get the ids upfront and save them, so that we do not need to query the
    # db with for each listing afterwards
    def self.get_condition_field_option_ids(condition_field_options)
      fabriksneu_id, neuwertig_id, gut_id, gebraucht_id = nil

      condition_field_options.each do |option|
        option.titles.each do |title|
          case title.value
            when "Fabriksneu"
              fabriksneu_id = title.custom_field_option_id

            when "Neuwertig"
              neuwertig_id = title.custom_field_option_id

            when "Gut"
              gut_id = title.custom_field_option_id

            when "Gebraucht"
              gebraucht_id = title.custom_field_option_id

            else
              #custom_field_option_fabriksneu_id = nil
          end
        end
      end

      condition_field_option_ids = {
        :fabriksneu => fabriksneu_id,
        :neuwertig  => neuwertig_id,
        :gut        => gut_id,
        :gebraucht  => gebraucht_id
      }
    end
end


