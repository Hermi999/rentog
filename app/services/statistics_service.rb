class StatisticsService
  def initialize(company_id, community_id)
    @rawData = getDataFromDb(company_id, community_id)
    @perListingData = getDataPerListing
    @perPersonData = getDataPerPerson
  end

  def averageDeviceBookingPeriod
    data = [[I18n.t("company_statistics.averageDeviceBookingPeriod_table_header_0"),
             I18n.t("company_statistics.averageDeviceBookingPeriod_table_header_1")]]
    @perListingData.each do |listing|
      data << [listing[1][:listing_title], listing[1][:sum_of_booked_days] / listing[1][:count_bookings]]
    end
    data
  end


  def peopleWithMostBookings
    # get the 10 users with the most transactions
    relevant_people = getXentriessOfYwithTheMostZ(10, @perPersonData, :count_bookings)

    # Split transactions into years and create an array out of them for the goolge barchart diagram
    data = createArrayForYWithMostZ(relevant_people, :person, :count_bookings, I18n.t("company_statistics.peopleWithMostBookings_table_header_0"))
  end

  def peopleWithMostBookedDays
    # get the 10 users with the most transactions
    relevant_people = getXentriessOfYwithTheMostZ(10, @perPersonData, :sum_of_booked_days)

    # Split transactions into years and create an array out of them for the goolge barchart diagram
    data = createArrayForYWithMostZ(relevant_people, :person, :sum_of_booked_days, I18n.t("company_statistics.peopleWithMostBookedDays_table_header_0"))
  end

  def devicesWithMostBookings
    # get the 10 users with the most transactions
    relevant_devices = getXentriessOfYwithTheMostZ(10, @perListingData, :count_bookings)

    # Split transactions into years and create an array out of them for the goolge barchart diagram
    data = createArrayForYWithMostZ(relevant_devices, :listing, :count_bookings, I18n.t("company_statistics.devicesWithMostBookings_table_header_0"))
  end

  def devicesWithMostBookedDays
    # get the 10 users with the most transactions
    relevant_devices = getXentriessOfYwithTheMostZ(10, @perListingData, :sum_of_booked_days)

    # Split transactions into years and create an array out of them for the goolge barchart diagram
    data = createArrayForYWithMostZ(relevant_devices, :listing, :sum_of_booked_days, I18n.t("company_statistics.devicesWithMostBookedDays_table_header_0"))
  end

  def bookingCompanyUnits
    data = [[I18n.t("company_statistics.bookingCompanyUnits_table_header_0")]]
    lowest_date = Date.new(3000)
    highest_date = Date.new(1000)

    # get lowest and highest quater of all person and their transactions
    @perPersonData.each do |person|
      person[1][:transactions].each do |tr|
        lowest_date  = tr[:start_on] if tr[:start_on] < lowest_date
        highest_date = tr[:start_on] if tr[:end_on] > highest_date
      end
    end

    lowest_year_and_quater = {
      quarter: ((lowest_date.month - 1) / 3) + 1,
      year: lowest_date.year
    }
    highest_year_and_quarter = {
      quarter: ((highest_date.month - 1) / 3) + 1,
      year: highest_date.year
    }


    @perPersonData.each do |person|
      # fill data array with quaters
      real_index = 0
      (lowest_year_and_quater[:year]..highest_year_and_quarter[:year]).each_with_index do |year, index|
        if year == lowest_year_and_quater[:year]
          cur_quarter = lowest_year_and_quater[:quarter]
          real_index = index + 1
        else
          cur_quarter = 1
        end

        (cur_quarter..4).each do |q|
          if year == highest_year_and_quarter[:year] && q > highest_year_and_quarter[:quarter]
            break
          end

          data[real_index] = [] unless data[real_index]
          data[real_index][0] = "Q" + q.to_s + " " + year.to_s
          real_index += 1
        end

      end

      # get index of company name and/or store the company name
      index_of_company_name = data[0].index person[1][:organization_name]
      unless index_of_company_name
        data[0] << person[1][:organization_name]
        index_of_company_name = data[0].index person[1][:organization_name]

        # write 0 by default for each quarter
        (1..data.length-1).each {|i| data[i][index_of_company_name] = 0 }
      end

      # add booking length of each transaction of the user to the companies quartal booked days
      person[1][:transactions].each do |tr|
        quarter = ((tr[:start_on].month - 1) / 3) + 1
        year = tr[:start_on].year
        row_index = data.index{|a,b| a == ("Q" + quarter.to_s + " " + year.to_s)}

        data[row_index][index_of_company_name] += (tr[:end_on] - tr[:start_on]).to_i + 1
      end
    end
    data
  end

  def deviceLivetime
    data = []
    @perListingData.each do |listing|
      closed_date =
        if listing[1][:listing_deleted] == 1
          listing[1][:listing_updated_at]
        else
          Time.now
        end
      data << [listing[1][:listing_title], listing[1][:listing_created_at].to_f * 1000, closed_date.to_f * 1000]
    end
    data
  end

  def userDeviceRelationship
    data = []
    @perPersonData.each do |person|
      if person[1][:is_organization] == 0
        name = person[1][:given_name] + " " + person[1][:family_name]
      else
        name = person[1][:organization_name]
      end

      person[1][:transactions].each do |tr|
        listing_title = tr[:listing_title]
        index = data.index {|user,device| user == name and device == listing_title}

        if index
          data[index][2] += 1
        else
          data << [name, listing_title, 1]
        end
      end
    end
    data
  end

  def deviceBookingDensityPerDay
    data = []
    @perPersonData.each do |person|
      person[1][:transactions].each do |tr|
        (tr[:start_on]..tr[:end_on]).each do |tr_day|
          index = data.index {|date, bookings| date == tr_day.to_time.to_f * 1000}

          if index
            data[index][1] += 1
          else
            data << [tr_day.to_time.to_f * 1000, 1]
          end
        end
      end
    end
    data
  end

  private

    def getDataFromDb(company_id, community_id)
      transaction_not_invalid = "(current_state <> 'rejected' OR current_state is null) AND
                                 (current_state <> 'errored'  OR current_state is null) AND
                                 (current_state <> 'canceled' OR current_state is null) AND
                                 (transactions.deleted = '0')"

      transactions = Transaction.joins(:listing, :booking, :starter).select(" transactions.id as transaction_id,
                                                                              listings.id as listing_id,
                                                                              listings.author_id as listing_author_id,
                                                                              listings.title as title,
                                                                              listings.availability as availability,
                                                                              listings.created_at as listing_created_at,
                                                                              listings.updated_at as listing_updated_at,
                                                                              listings.deleted as listing_deleted,
                                                                              bookings.start_on as start_on,
                                                                              bookings.end_on as end_on,
                                                                              bookings.reason as reason,
                                                                              bookings.description as description,
                                                                              bookings.device_returned as device_returned,
                                                                              transactions.current_state as transaction_status,
                                                                              people.given_name as renter_given_name,
                                                                              people.family_name as renter_family_name,
                                                                              people.username as renting_entity_username,
                                                                              people.organization_name as renting_entity_organame,
                                                                              people.is_organization as renter_is_organization,
                                                                              people.id as renter_id")
                                                                    .where("  listings.author_id = ? AND
                                                                              transactions.community_id = ? AND
                                                                              #{transaction_not_invalid}",
                                                                              company_id, community_id)
                                                                    .order("  listings.id asc")
    end

    def getDataPerListing
      temp = {}
      @rawData.each do |tr|
        if temp[tr.listing_id.to_s] == nil
          temp[tr.listing_id.to_s] = {  listing_title: tr.title,
                                        listing_author_id: tr.listing_author_id,
                                        listing_renter_is_organization: tr.renter_is_organization,
                                        listing_created_at: tr.listing_created_at,
                                        listing_updated_at: tr.listing_updated_at,
                                        listing_deleted: tr.listing_deleted,
                                        count_bookings: 0,
                                        sum_of_booked_days: 0,
                                        transactions: [] }
        end
        temp[tr.listing_id.to_s][:sum_of_booked_days] += ((tr.end_on - tr.start_on).to_i + 1)
        temp[tr.listing_id.to_s][:count_bookings] += 1
        temp[tr.listing_id.to_s][:transactions] << { start_on: tr.start_on,
                                                     end_on: tr.end_on }
      end
      temp
    end

    def getDataPerPerson
      temp = {}
      @rawData.each do |tr|
        if temp[tr.renter_id] == nil
          temp[tr.renter_id] = {  given_name: tr.renter_given_name,
                                  family_name: tr.renter_family_name,
                                  is_organization: tr.renter_is_organization,
                                  organization_name: tr.renting_entity_organame,
                                  count_bookings: 0,
                                  sum_of_booked_days: 0,
                                  transactions: [] }
        end
        temp[tr.renter_id][:sum_of_booked_days] += ((tr.end_on - tr.start_on).to_i + 1)
        temp[tr.renter_id][:count_bookings] += 1
        temp[tr.renter_id][:transactions] << { listing_title: tr.title,
                                               listing_author: tr.listing_author_id,
                                               start_on: tr.start_on,
                                               end_on: tr.end_on }
        temp
      end

      # get all organization_names
      employee_ids = []

      temp.each{|renter| employee_ids << renter[0] if (renter[1][:organization_name] == "" or renter[1][:organization_name] == nil)}

      employments = Employment.joins(:company)
                              .select("employee_id, company_id, organization_name")
                              .where("employee_id IN (?)", employee_ids)

      temp.each do |renter|
        if renter[1][:organization_name] == "" or renter[1][:organization_name] == nil
          employments.each do |empl|
            if empl.employee_id == renter[0]
              renter[1][:organization_name] = empl.organization_name
            end
          end
        end
      end
      temp
    end

    def getXentriessOfYwithTheMostZ(x, y, z)
      relevant_data = []
      lowest = 0

      y.each do |entry|

        # if the user has more transaction days than the current lowest
        if relevant_data.length < x
          relevant_data << entry[1]
        elsif entry[1][z] >= lowest
          relevant_data[x-1] == entry[1]
        end
        # sort the array desc
        relevant_data.sort! { |a,b| a[z] <=> b[z] }.reverse!

        # store the current lowest transaction count
        lowest = relevant_data[-1][z]
      end
      relevant_data
    end

    def createArrayForYWithMostZ(relevant_data, y, z, header)
      data = []
      lowest_year = 3000
      highest_year = 0

      relevant_data.each do |entry|
        # get the hightest an lowest year of the transactions
        entry[:transactions].each do |tr|
          lowest_year = tr[:start_on].year if tr[:start_on].year < lowest_year
          highest_year = tr[:start_on].year if tr[:start_on].year > highest_year
        end
      end

      relevant_data.each do |entry|
        # create entry arry with default entry (0) for each year
        if y == :person
          if entry[:is_organization] == 0
            temp = [entry[:given_name] + " " + entry[:family_name]]
          else
            temp = [entry[:organization_name]]
          end
        elsif y == :listing
          temp = [entry[:listing_title]]
        end

        (lowest_year..highest_year).each{|year| temp << 0}

        # count bookings/booking days for each year
        entry[:transactions].each do |tr|
          if z == :count_bookings
            temp[tr[:start_on].year - lowest_year + 1] += 1
          elsif z == :sum_of_booked_days
            temp[tr[:start_on].year - lowest_year + 1] += (tr[:end_on] - tr[:start_on]).to_i + 1
          end
        end

        # insert table attributs
        data << ([header] + (lowest_year..highest_year).to_a.map{|i| i.to_s}) if data == []
        data << temp
      end
      data
    end
end
