# Used to
#   - extract data for the  KPI line chart      (kpi_details)
#   - extract data for KPI Rentog admin email   (kpi_numbers)

class KpiService
  def initialize(interval_length=nil, interval_count=nil)
    if interval_length && interval_count
      get_kpis(interval_length, interval_count)
    end
  end

  # returns interval counts for a specific model and/or query
  # Parameters:
  #   - model ............. Model which should be used to fetch the data
  #   - query ............. Additional db query (where)
  #   - interval_length ... days, weeks, months, etc.
  #   - interval_count .... how many previous periods should be fetched
  #
  # Result:
  #   - Schema:   [count of all results for query, count for intervall 1, count for interval 2, ...]
  #   - Example:  [20, 10, 3, 4, 3, 0, 0]     with params: (Visitor, "", 7, 6)
  def kpi_numbers_for_model_and_interval(model, query, interval_length, interval_count)
    result = []
    all = model.where(query).count

    query = "AND (" + query + ")" if (query && query != "")

    (1..interval_count).each do |interval|
      start_ = Date.today - (interval * interval_length)
      end_   = Date.today - (interval * interval_length) + (interval_length-1)

      result << model.where("created_at < ? AND created_at > ?" + query, end_, start_).count
    end

    result = [all] + result.reverse
  end

  # l ... interval_length, eg. 7 for 7 days
  # c ... interval_count,  eg. 3 for the last 3, 7 days periods
  def get_kpis(l, c)
    kpis = {
      unique_visitors:         kpi_numbers_for_model_and_interval(Visitor, "", l, c),
      campaign_visitors:       kpi_numbers_for_model_and_interval(RentogEvent, "event_name = 'campaign'", l, c),
      signups:                 kpi_numbers_for_model_and_interval(RentogEvent, "event_name = 'signup'", l, c),
      device_requests:         kpi_numbers_for_model_and_interval(ListingRequest, "", l, c),
      invitations:             kpi_numbers_for_model_and_interval(Invitation, "", l, c),
      listings_created:        kpi_numbers_for_model_and_interval(ListingEvent, "event_name = 'listing_created'", l, c),
      #listing_visits:          kpi_numbers_for_model_and_interval(ListingEvent, "event_name = 'listing_viewed_unique'", l, c),
      search_filter_used:      kpi_numbers_for_model_and_interval(RentogEvent, "event_name = 'marketplace_search_or_filter'", l, c),
      search_filter_result_0:  kpi_numbers_for_model_and_interval(RentogEvent, "event_name = 'marketplace_search_or_filter' AND event_result = 0", l, c),
    }
  end

  def get_kpis_values_with_growth(l, c)
    kpi_hash = get_kpis(l, c)

    kpi_hash.each_with_index do |kpi_category, i|
      all = kpi_category[1].first

      kpi_category[1].each_with_index do |kpi, index|

        if index > 0
          # get growth ... growth = 100 / all * new
          growth = (all > 0) ? (100.to_f / all * kpi) : 0
          kpi = [kpi, growth.round(2)]
        end

      end
    end
  end

  def get_kpis_for_chart(l, c)
    kpi_hash = get_kpis(l, c)

    # transpose array and remove first line (sum line)
    arr = kpi_hash.values.transpose[1..-1]

    # add date column as first
    arr.each_with_index do |row, index|
      start_ = Date.today - ((arr.length - index) * l)
      end_   = Date.today - ((arr.length - index) * l) + (l-1)

      arr[index] = [start_.strftime("%d.%m") + " - " + end_.strftime("%d.%m")] + arr[index]
    end

    # add headline
    arr = [["Date"] + kpi_hash.keys.map{|e| e.to_s.gsub("_", " ")}] + arr

  end

end


