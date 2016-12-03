require 'roo'

class DeleteListingsService
  attr_reader :error_text, :listing_data, :invalid_rows, :listings

  def initialize(filepath, current_user, relation)    
    @listings = []

    # Open the new file & get the attributes row from it
    @relation = relation
    @file = Roo::Spreadsheet.open(filepath, extension: :xlsx)
    @excel_attributes_raw = @file.sheet(0).row(1)

    # validate attributes row
    @invalid_rows = false
    @mandatory_attributes = ["Hidden upload id", "Username"]

    # check if mandatory attributes are there
    @mandatory_attributes.each do |mand_attr|
      unless @excel_attributes_raw.include? mand_attr
        @error_text = "Mandatory attribute: '" + mand_attr + "' missing"
      end
    end

    # if no attribute missing
    unless @error_text
      # get all values the rows below the attribute row
      parse_args = {}
      @excel_attributes_raw.each{ |x_attr| parse_args[x_attr.to_sym] = x_attr }
      @listing_data = @file.parse(parse_args)

      # check if there exists a value for mandatory attributes
      checkListingAttributeRequirements
    else

    end

    hidden_id_custom_field_id = CustomFieldName.where(value: "Hidden upload id")[0].custom_field_id
    
    @listing_data.each_with_index do |listing, index|
      if index > 0
        listing_hidden_upload_id = listing["Hidden upload id".to_sym]
        listing_author = Person.where(username: listing[:Username]).first

        res = Listing.joins("INNER JOIN custom_field_values ON custom_field_values.listing_id = listings.id").where(custom_field_values: {custom_field_id: hidden_id_custom_field_id, text_value: listing_hidden_upload_id}, listings: {author_id: listing_author.id})

        @listings << res[0] if res.length > 0
      end
    end

  end

  def deleteListings
    @listings.each {|listing| listing.update_attribute(:deleted, true)}
  end


  private

    # each mandatory attribute has to be within each row
    def checkListingAttributeRequirements
      @mandatory_attributes.each do |mand_attr|
        @listing_data.each do |listing|
          if listing[mand_attr.to_sym] == nil
            listing[mand_attr.to_sym] = "#mand_attr_missing"
            listing[:invalid] = "Mandatory attribute #{mand_attr} missing!"
            @invalid_rows = true
          end
        end
      end
    end
end