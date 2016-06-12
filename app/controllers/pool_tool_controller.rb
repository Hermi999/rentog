class PoolToolController < ApplicationController
  # Filters
  before_filter :ensure_is_authorized_to_view, :only => [ :show]


  def show
    # Is admin or employee of company or domain supervisor (or rentog admin)?
    @belongs_to_company = (@relation == :company_admin_own_site || @relation == :company_employee || @relation == :rentog_admin || @relation == :domain_supervisor || @relation == :rentog_admin_own_site)
    @is_member_of_company = (@relation == :company_admin_own_site || @relation == :company_employee || @relation == :rentog_admin_own_site)

    @domain_supervisor_on_overview_site = @relation == :domain_supervisor && params[:domain_view]

    # CHANGE BUTTONS TEXTs
    addjustButtonText



    ### OPEN LISTINGS ###
      open_listings_array = []
      listing_ids_of_other_companies = []

      if @relation == :domain_supervisor
        @companies_in_same_domain = @current_user.get_companies_with_same_domain
      end

      # IF USER IS SUPERVISOR OF POOL OWNER and HE IS IN OVERVIEW MODE
      if @domain_supervisor_on_overview_site
        # get all the domains listings and their ids
        all_domain_listings = get_listings_of_companies(@companies_in_same_domain.map(&:id))
        listing_ids_of_other_companies = all_domain_listings.map(&:id)

        # Filter attributes for JS
        all_domain_listings.each do |listing|
            small_image = listing.listing_images.first.image.url(:small_3x2) if listing.listing_images.first
            open_listings_array << {  name: listing.title,
                                      desc: listing.availability,
                                      listing_author_id: listing.author_id,
                                      availability: listing.availability,
                                      listing_id: listing.id,
                                      created_at: listing.created_at,
                                      image: small_image,
                                      listing_author_organization_name: listing.author.organization_name,
                                      location_alias: Maybe(listing.location).location_alias.or_else(nil) || Maybe(listing.author.location).location_alias.or_else(nil) }
          end
      else

        # get the open listings of the pool owner (only trusted and global if visitor who does not belong to company)
        company_listings = get_pool_owners_open_listings

        # If company admin wants it this way, then also show devices of companies who trust the owner in the pool tool
        if @belongs_to_company && Maybe(@site_owner.company_option).pool_tool_show_all_available_devices.or_else(false)

          # get the open listings of companies who trust the pool owner
          ext_open_listings = get_listings_of_other_companies

          # get all the external listing ids
          listing_ids_of_other_companies = ext_open_listings.map(&:id)

          # Only use certain fields in JS for internal and external devices
          ext_open_listings.each do |listing|
            small_image = listing.listing_images.first.image.url(:small_3x2) if listing.listing_images.first
            open_listings_array << {  name: listing.title,
                                      desc: "extern",
                                      listing_author_id: listing.author_id,
                                      availability: listing.availability,
                                      listing_id: listing.id,
                                      created_at: listing.created_at,
                                      image: small_image,
                                      listing_author_organization_name: listing.author.organization_name,
                                      location_alias: Maybe(listing.location).location_alias.or_else(nil) || Maybe(listing.author.location).location_alias.or_else(nil) }
          end
        end

        # ADD THE INTERNAL OPEN LISTINGS OF COMPANY
        company_listings.each do |listing|
          small_image = listing.listing_images.first.small_3x2 if listing.listing_images.first
          open_listings_array << {  name: listing.title,
                                    desc: listing.availability,
                                    availability: listing.availability,
                                    listing_id: listing.id,
                                    created_at: listing.created_at,
                                    image: small_image,
                                    listing_author_organization_name: listing.author.organization_name,
                                    location_alias: listing.location_alias || listing.author.location_alias }
        end
      end

    ### TRANSACTIONS ###
      # IF USER IS SUPERVISOR OF POOL OWNER
      if @domain_supervisor_on_overview_site
        transactions = get_domain_transactions(listing_ids_of_other_companies)
        transaction_array = transactions.as_json

      else
        # GET ALL THE POOL OWNERS TRANSACTIONS WITH OWN LISTINGS
        intern_transactions = get_transactions_with_own_listings

        # GET ALL POOL OWNERS TRANSACTIONS WITH LISTINGS OF OTHER COMPANIES
        extern_transactions = []
        extern_transactions = get_transactions_with_listings_from_other_companies(listing_ids_of_other_companies) if @belongs_to_company

        # Combine them and turn them into array
        transactions = intern_transactions + extern_transactions
        transaction_array = transactions.as_json
      end


    ### JAVASCRIPT DATA TRANSFORMATION
      # Convert all the transaction into a jquery-Gantt readable source.
      # wah: This might be shifted to the client (javascript) in future, since
      # it would reduce load on the server
      devices = []
      act_transaction = {}
      prev_listing_id = 0, counter = -1

      # wah: Get all possible company ids of companies which can be shown in pool tool
      possible_companies =
        if @domain_supervisor_on_overview_site
          @companies_in_same_domain
        else
          Person.where(:id => ([@site_owner] + @site_owner.followers))
        end


      transaction_array.each do |transaction|

        # get the status of the transaction (pending or confirmed)
        get_transaction_status(transaction)

        # returns what relation a specific transaction has to the company
        tr_starter = get_transaction_starter_and_relation(transaction)

        # Update the title and the description of the booking according to
        # the different transaction types
        edit_tr_title_and_description(transaction, tr_starter, possible_companies)


        if prev_listing_id != transaction['listing_id']
          # new Listing, new transaction
          counter = counter + 1

          availability = transaction['availability'] || "extern"
          loc_alias = Maybe(Location.where(listing_id: transaction['listing_id']).first).location_alias.or_else(nil)
          loc_alias = Maybe(Location.where(person_id: transaction['listing_author_id']).first).location_alias.or_else(nil) if loc_alias == nil || loc_alias == ""

          transaction['name'] = transaction['title']
          transaction['desc'] = availability
          transaction['location_alias'] = loc_alias
          transaction['already_booked_dates'] = Listing.already_booked_dates(transaction['listing_id'], @current_community)

          # set the transaction specific values of the first element in the transaction array of this listing
          transaction['values'] = [set_transaction_element_values(transaction, tr_starter)]

          if availability == "extern"
            temp_listing = Listing.where(:id => transaction['listing_id']).first
            transaction['image'] = temp_listing.listing_images.first.image.url(:small_3x2) if temp_listing.listing_images.first
          end

          # Remove unused keys from hash
          transaction.except!('title', 'start_on', 'end_on', 'renting_entity_username', 'renting_entity_organame', 'transaction_id', 'renter_family_name', 'renter_given_name', 'renter_id')

          prev_listing_id = transaction['listing_id']
          act_transaction = transaction
          devices << transaction

        else
          # Previous Listing, new transaction
          # add transaction specific values to the transaction array of this listing
          newTrans = set_transaction_element_values(transaction, tr_starter)
          devices[counter]['values'] << newTrans
        end
      end

    ### DEVICE RETURN - OPEN BOOKINGS OF CURRENT USER (if member of company) ###
      # Get only bookings which are booked by the user AND are currently in state
      # active (that means the user hadn't give them back) AND are past, but the
      # user did not return them
        @user_bookings_array = []
        if @is_member_of_company
          user_bookings1 = intern_transactions.where("people.id = ? AND ((bookings.start_on <= ? AND bookings.end_on >= ? AND bookings.device_returned = false) OR (bookings.end_on < ? AND bookings.device_returned = false))", @current_user.id, Date.today, Date.today, Date.today)
          user_bookings2 = extern_transactions.where("people.id = ? AND ((bookings.start_on <= ? AND bookings.end_on >= ? AND bookings.device_returned = false) OR (bookings.end_on < ? AND bookings.device_returned = false))", @current_user.id, Date.today, Date.today, Date.today)
          @user_bookings_array = user_bookings1.as_json + user_bookings2.as_json
        end

    # Variables which should be send to JavaScript
    poolTool_gon_vars(devices, open_listings_array)

    render locals: { company_listings: company_listings, open_listings_array: open_listings_array, transactions: transactions }
  end

  # get the current theme of the user from the db
  def get_theme
    respond_to do |format|
      format.json { render :json => {theme: @current_user.pool_tool_color_schema} }
    end
  end

  # sets the choosen theme of the user in the db
  def set_theme
    # Save in db
    @current_user.update_attribute :pool_tool_color_schema, params['theme']

    respond_to do |format|
      format.json { render :json => {theme: @current_user.pool_tool_color_schema} }
    end
  end

  def set_legend
    # Save in db
    if params['legend'] == "true"
      @current_user.update_attribute :pool_tool_show_legend, "1"
    else
      @current_user.update_attribute :pool_tool_show_legend, "0"
    end

    respond_to do |format|
      format.json { render :json => {show_legend: @current_user.pool_tool_show_legend} }
    end
  end

  private

    def ensure_is_authorized_to_view
      # ALLOWED
      return if @relation == :rentog_admin ||
                @relation == :rentog_admin_own_site ||
                @relation == :domain_supervisor ||
                @relation == :company_admin_own_site ||
                @relation == :company_employee ||
                @relation == :trusted_company_admin ||
                @relation == :full_trusted_company_admin ||
                @relation == :trusted_company_employee ||
                @relation == :full_trusted_company_employee


      # NOT ALLOWED
        # no error message
        redirect_to person_poolTool_path(@current_user.company) and return false if @relation == :employee_own_site

        # with error message
        flash[:error] = t("pool_tool.you_have_to_be_company_member")
        redirect_to person_poolTool_path(@current_user)         if @relation == :untrusted_company_admin
        redirect_to person_poolTool_path(@current_user.company) if @relation == :untrusted_company_employee
        redirect_to login_path                                  if @relation == :logged_out_user
        return false
    end


    def get_pool_owners_open_listings
      # If the visitor does not "belong" to the company, then hide internal listings
      temp_avail =
        if @belongs_to_company
          Listing::VALID_AVAILABILITY_OPTIONS
        else
          Listing::TRUSTED_AVAILABILITY_OPTIONS
        end

      search = {
        author_id: @site_owner.id,
        include_closed: false,
        page: 1,
        per_page: 1000,
        availability: temp_avail
      }

      includes = [:author, :listing_images, :location]
      company_listings = ListingIndexService::API::Api.listings.search(community_id: @current_community.id, search: search, includes: includes).and_then { |res|
        Result::Success.new(
          ListingIndexViewUtils.to_struct(
          result: res,
          includes: includes,
          page: search[:page],
          per_page: search[:per_page],
        ))
      }.data
    end

    def get_listings_of_other_companies
      follower_ids = []
      @site_owner.followers.each{|person| follower_ids<<person.id}

      ext_open_listings = Listing.where("listings.author_id IN (?) AND
                                         listings.open = '1' AND
                                         listings.deleted = '0' AND
                                         (listings.valid_until IS NULL OR valid_until > ?) AND
                                         (listings.availability = 'all' OR listings.availability = 'trusted')",
                                         follower_ids, Date.today)
    end

    def get_listings_of_companies(ids)
      ext_open_listings = Listing.where("listings.author_id IN (?) AND
                                         listings.open = '1' AND
                                         listings.deleted = '0' AND
                                         (listings.valid_until IS NULL OR valid_until > ?) AND
                                         (listings.availability = 'all' OR listings.availability = 'intern' OR listings.availability = 'trusted')",
                                         ids, Date.today)
    end

    def get_domain_transactions(domain_pool_ids)
      transaction_not_invalid = "(current_state <> 'rejected' OR current_state is null) AND
                                 (current_state <> 'errored'  OR current_state is null) AND
                                 (current_state <> 'canceled' OR current_state is null) AND
                                 (transactions.deleted = '0')"

      temp_avail2 = "(listings.availability = 'all' OR listings.availability = 'intern' OR listings.availability = 'trusted')"

      transactions = Transaction.joins(:listing, :booking, :starter).select(" transactions.id as transaction_id,
                                                                              listings.id as listing_id,
                                                                              listings.author_id as listing_author_id,
                                                                              listings.title as title,
                                                                              listings.availability as availability,
                                                                              listings.created_at,
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
                                                                              people.id as renter_id")
                                                                    .where("  listings.id IN (?) AND
                                                                              listings.deleted = '0' AND
                                                                              transactions.community_id = ? AND
                                                                              #{transaction_not_invalid} AND
                                                                              listings.open = '1' AND
                                                                              #{temp_avail2} AND
                                                                              (listings.valid_until IS NULL OR valid_until > ?)",
                                                                              domain_pool_ids, @current_community.id, DateTime.now)
                                                                    .order("  listings.id asc")

    end


    def get_transactions_with_own_listings
      temp_avail2 =
        if @belongs_to_company
          "(listings.availability = 'all' OR listings.availability = 'intern' OR listings.availability = 'trusted')"
        else
          "(listings.availability = 'all' OR listings.availability = 'trusted')"
        end

      transaction_not_invalid = "(current_state <> 'rejected' OR current_state is null) AND
                                 (current_state <> 'errored'  OR current_state is null) AND
                                 (current_state <> 'canceled' OR current_state is null) AND
                                 (transactions.deleted = '0')"

      transactions = Transaction.joins(:listing, :booking, :starter).select(" transactions.id as transaction_id,
                                                                              listings.id as listing_id,
                                                                              listings.author_id as listing_author_id,
                                                                              listings.title as title,
                                                                              listings.availability as availability,
                                                                              listings.created_at,
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
                                                                              people.id as renter_id")
                                                                    .where("  listings.author_id = ? AND
                                                                              listings.deleted = '0' AND
                                                                              transactions.community_id = ? AND
                                                                              #{transaction_not_invalid} AND
                                                                              listings.open = '1' AND
                                                                              #{temp_avail2} AND
                                                                              (listings.valid_until IS NULL OR valid_until > ?)",
                                                                              @site_owner.id, @current_community.id, DateTime.now)
                                                                    .order("  listings.id asc")


      # Add company name to transactions of external trusted employees
        transactions.each_with_index do |ext_tr, index|
          if ext_tr[:renting_entity_organame] == nil
            transactions[index][:renting_entity_organame] = Person.find(ext_tr[:renter_id]).get_company_name
          end
        end

        transactions
    end


    def get_transactions_with_listings_from_other_companies(listing_ids_of_other_companies)
      # dont retrieve transaction which are in the following state
      transaction_not_invalid = "(current_state <> 'rejected' OR current_state is null) AND
                                 (current_state <> 'errored'  OR current_state is null) AND
                                 (current_state <> 'canceled' OR current_state is null) AND
                                 (transactions.deleted = '0')"


      # 1 FIND OUT WHICH EXTERNAL LISTINGS WHERE BOOKED BY COMPANY MEMBERS
        # 1a Get the ids of all company members
        all_users = @site_owner.get_company_members
        user_ids = []
        all_users.each do |user|
          user_ids << user.id
        end

        # 1b Get all extern transactions this users will have in future, are currently active, valied and or are not closed (device not returned)
        company_external_transactions = Transaction.joins(:booking).where(" transactions.starter_id IN (?) AND
                                                                            transactions.community_id = ? AND
                                                                            transactions.listing_author_id <> ? AND
                                                                            #{transaction_not_invalid} AND
                                                                            (bookings.end_on > ? OR bookings.device_returned = false)",
                                                                            user_ids, @current_community.id, @site_owner, DateTime.now)


        # 1c Extract the extern listings from the extern transactions
        ext_listings_ids = []
        company_external_transactions.each do |ext_trans|
          ext_listings_ids << Listing.find(ext_trans.listing_id).id
        end

        # 1d Add listing ids from all companies who trust me & remove duplicates
        ext_listings_ids += listing_ids_of_other_companies
        ext_listings_ids = ext_listings_ids.uniq

        @ext_listings_count = ext_listings_ids.count


      # 2 GET ALL THE TRANSACTION, BOOKING & LISTING DETAILS FOR ALL LISTINGS WITH OPEN TRANSACTIONS FOR THIS COMPANY
        company_external_transactions2 = Transaction.joins(:listing, :booking, :starter).select("transactions.id as transaction_id,
                                                                                          listings.id as listing_id,
                                                                                          listings.author_id as listing_author_id,
                                                                                          listings.title as title,
                                                                                          listings.created_at,
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
                                                                                          people.id as renter_id")
                                                                                .where("  listings.id IN (?) AND
                                                                                          listings.deleted = '0' AND
                                                                                          transactions.community_id = ? AND
                                                                                          #{transaction_not_invalid} AND
                                                                                          listings.open = '1' AND
                                                                                          (bookings.end_on > ? OR bookings.device_returned = false) AND
                                                                                          (listings.valid_until IS NULL OR valid_until > ?) AND
                                                                                          (listings.availability = 'all' OR listings.availability = 'trusted')",
                                                                                          ext_listings_ids, @current_community.id, DateTime.now, DateTime.now)
                                                                                .order("  listings.id asc")
    end


    # returns what relation a specific transaction has to the company
    def get_transaction_starter_and_relation(transaction)
      # How is the relation between the company & the renter of this one listing?
        renter = Person.where(id: transaction["renter_id"]).first

        # If is this is a not verified request
        if @transaction_confirmed == false
          relation = "rentingRequest"

        # If the current user DOES belong to company AND the listing is from another company AND the booking is from another company
        elsif @belongs_to_company &&                                              # current user does belong to pool tool company
           transaction['listing_author_id'] != @current_user.get_company.id &&    # listing author is not the company the current user belongs to
           @current_user != renter &&                                             # current user is not the initiator of this transaction
          !@current_user.employs?(renter) &&                                      # current user does not employee initiator of this transaction
           @current_user.company != renter &&                                     # current user is not employee of the renter
           @current_user.get_company != renter.get_company &&                     # current user is not from same company as renter
           @relation != :rentog_admin &&                                          # current user is not a Rentog admin
           @relation != :domain_supervisor                                        # current user is not a Domain Supervisor
                  relation = "privateBooking"

        # If the current user DOES NOT belong to company AND the booking is from another company
        elsif !@belongs_to_company &&                                             # current user does not belong to pool tool company
               @current_user != renter &&                                         # Current user is not the initiator of this transaction
              !@current_user.employs?(renter) &&                                  # current user does not employee initiator of this transaction
               @current_user.company != renter &&                                 # current user is not employee of the renter
               @current_user.get_company != renter.get_company &&                 # current user is not from same company as renter
               @relation != :rentog_admin &&                                      # current user is not a Rentog admin
               @relation != :domain_supervisor                                    # current user is not a Domain Supervisor
                  relation = "privateBooking"

        # if the current user is a domain supervisor AND the listing does not belong to his domain AND the renter does not belong to his domain
        elsif @relation == :domain_supervisor &&                                  # current user is a Domain Supervisor
              !@current_user.belongs_to_same_domain?(renter) &&                    # current user is NOT in same domain like the renter
              !@current_user.get_companies_with_same_domain.map(&:id).include?(transaction['listing_author_id'])   # listing author is not in the same domain
                  relation = "privateBooking"

        elsif @relation == :domain_supervisor
          if @current_user.belongs_to_same_domain?(renter)
            relation = "sameDomain"
          else
            relation = "otherDomain"
          end

        elsif renter.is_organization
          # Company is renting listing
          if @site_owner.follows?(renter)
            # Other company is trusted by the company
            relation = "trustedCompany"
          elsif renter == @site_owner
            relation = "otherReason"
          else
            # Other company is not trusted by the company
            relation = "anyCompany"
          end
        else
          # Any Employee is renting listing
          if renter.is_employee_of?(@site_owner.id)
            # Own employee is renting listing
            relation = "ownEmployee"
          else
            # Employee of another company is renting listing
            relation = "trustedEmployee"
          end
        end

        # If renter is the current user
        if renter == @current_user
          relation = relation + "_me"
        end

        { renter: renter, relation: relation }
    end

    # Update the title and the description of the booking according to
    # the different transaction types
    def edit_tr_title_and_description(transaction, tr_starter, possible_companies)
      renting_entity = nil

      # Transaction not accepted yet by author
      if @transaction_pending
        if transaction['renter_id'] == @current_user.id
          renting_entity = t("pool_tool.show.own_renting_request")
        else
          renting_entity = t("pool_tool.show.renting_request") + " (" + transaction['renting_entity_organame'] + ")"
        end

      # This is a admin transaction with a reason (maintainance, ...)
      elsif transaction['reason']
        renting_entity = transaction['reason']

      # Trusted Company or trusted Employee
      elsif (tr_starter[:relation] == "trustedCompany" ||
             tr_starter[:relation] == "trustedEmployee"||
             tr_starter[:relation] == "anyCompany")    &&
             transaction['renting_entity_organame'] != "" &&
             transaction['renting_entity_organame'] != nil
        renting_entity = transaction['renter_family_name'] + " " + transaction['renter_given_name'] + " (" + transaction['renting_entity_organame'] + ")"

      #
      else
        renting_entity = transaction['renter_family_name'] + " " + transaction['renter_given_name']
      end


      # get author of a listing
      possible_companies.each do |company|
        if company.id == transaction['listing_author_id']
          transaction['listing_author_username'] = company.username
          transaction['listing_author_organization_name'] = company.organization_name
        end
      end

      # Hide description and who booked the device, if visitor does not belong
      # to company at booking is not his or his employees_do_not_post
      if !@belongs_to_company && tr_starter[:relation] == "privateBooking"
        transaction['description'] = 'private'
        renting_entity = 'private'
      end

      # Hide description and who booked the devices, if
      #   - a company member is viewing the pool tool
      #   - the listing author is not the pool tool ower and
      #   - the booking is not related to a company member
      if @belongs_to_company &&
         transaction['listing_author_id'] != @site_owner.id &&
         tr_starter[:relation] == "privateBooking"

            transaction['description'] = 'private'
            renting_entity = 'private'
      end

      transaction['renting_entity'] = renting_entity
    end

    # set the values of the first element in the transaction array of this listing
    def set_transaction_element_values(transaction, tr_starter)
      location_alias =
        if tr_starter[:renter].location
          if tr_starter[:renter].location.location_alias && tr_starter[:renter].location.location_alias != ""
            tr_starter[:renter].location.location_alias
          else
            tr_starter[:renter].get_company.location.location_alias
          end
        else
          Maybe(tr_starter[:renter].get_company.location).location_alias.or_else(nil)
        end

      {
        'from' => "/Date(" + transaction['start_on'].to_time.to_i.to_s + "000)/",
        'to' => "/Date(" + transaction['end_on'].to_time.to_i.to_s + "000)/",
        'label' => transaction['renting_entity'],
        'customClass' => "gantt_" + tr_starter[:relation],
        'transaction_id' => transaction['transaction_id'],
        'renter_id' => transaction['renter_id'],
        'renter_company_id' => tr_starter[:renter].get_company.id,
        'renter_location_alias' => location_alias,
        'description' => transaction['description'],
        'confirmed' => @transaction_confirmed
      }
    end

    # Depending if the user is already member of a shared pool or not and if the
    # visitor is part of the company, the button text is changed
    def addjustButtonText
      if @belongs_to_company
        @add_booking_text = t('pool_tool.show.addNewBooking')

        # If no company trusts me
        if @site_owner.followers == []
          @external_booking_text = t('pool_tool.show.createSharedPool')
          @external_booking_link = get_wp_url("blog/2016/03/10/create-shared-pool")
        else
          @external_booking_text = t('pool_tool.show.newExternalBooking')
          @external_booking_link = marketplace_path(:restrictedMarketplace => "1")
        end
      else
        @add_booking_text = t('pool_tool.show.addNewBooking_visitor')
        @external_booking_text = t('pool_tool.show.newExternalBooking_visitor')
        @external_booking_link = marketplace_path(:restrictedMarketplace => "1")
      end
    end

    def get_transaction_status(transaction)
      @transaction_confirmed = false
      @transaction_pending = false

      case transaction['transaction_status']
        when nil, "confirmed", "confirmed_free"
          @transaction_confirmed = true
        when "pending", "pending_free", "pending_ext", "preauthorized", "accepted", "paid"
        else
          @transaction_pending = true
        end
    end

    # sets all variables which are needed in Javascript on the client side
    def poolTool_gon_vars(devices, open_listings_array)
      # Variables which should be send to JavaScript
      days =    [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
      months =  [:january, :february, :march, :april, :may, :june, :july, :august, :september, :october, :november, :december]

      button_text =
      if @belongs_to_company
        t("pool_tool.show.addNewBooking")
      else
        t("pool_tool.show.addNewBooking_visitor")
      end

      gon.push({
        devices: devices,                               # holds listings with transactions (values) for gantt chart and also the already_booked_dates for the calendar
        open_listings: open_listings_array,             # holds all listings (even those with no transactions)
        user_active_bookings: @user_bookings_array,     # holds the currently open bookings of the user
        count_extern_listings: @ext_listings_count,  # number of extern listings

        only_pool_tool: @current_community.only_pool_tool,
        locale: I18n.locale,
        days: days,
        months: months,
        translated_days: days.map { |day_symbol| t("datepicker.days.#{day_symbol}") },
        translated_days_short: days.map { |day_symbol| t("datepicker.days_short.#{day_symbol}") },
        translated_days_min: days.map { |day_symbol| t("datepicker.days_min.#{day_symbol}") },
        translated_months: months.map { |day_symbol| t("datepicker.months.#{day_symbol}") },
        translated_months_short: months.map { |day_symbol| t("datepicker.months_short.#{day_symbol}") },
        today: t("datepicker.today"),
        week_start: t("datepicker.week_start", default: 0),
        clear: t("datepicker.clear"),
        format: t("datepicker.format"),
        pooltool_owner_id: @site_owner.id,
        current_user_id: @current_user.id,
        current_user_username: @current_user.username,
        current_user_email: @current_user.emails.first.address,
        is_admin: @current_user.is_company_admin_of?(@site_owner) || @current_user.has_admin_rights_in?(@current_community),
        is_supervisor: @current_user.is_supervisor_of?(@site_owner),
        belongs_to_company: @belongs_to_company,
        owner_has_followers: (@site_owner.followers != []),
        theme: @current_user.pool_tool_color_schema,
        legend_status: @current_user.pool_tool_show_legend,
        show_legend: t("pool_tool.show.show_legend"),
        hide_legend: t("pool_tool.show.hide_legend"),
        add_booking: button_text,
        cancel_booking: t("pool_tool.cancel_booking"),
        device_name: t("pool_tool.device_name"),
        comment: t("pool_tool.comment"),
        choose_employee_or_renter_msg: t("pool_tool.show.choose_employee_or_renter"),
        deleteConfirmation: t("pool_tool.deleteConfirmation"),
        legend: t("pool_tool.show.legend"),
        trusted_company: t("pool_tool.show.trusted_company"),
        any_company: t("pool_tool.show.any_company"),
        own_employee: t("pool_tool.show.own_employee"),
        any_employee: t("pool_tool.show.any_employee"),
        other_reason: t("pool_tool.show.other_reason"),
        only_mine: t("pool_tool.show.only_mine"),
        show_location: t("pool_tool.show.show_location"),
        no_location_available: t("pool_tool.show.no_location_available"),
        no_devices_borrowed: t("pool_tool.show.no_devices_borrowed"),
        return_now: t("pool_tool.show.return_now"),
        utilization_header: t("pool_tool.load_popover.utilization_header"),
        utilization_desc_1: t("pool_tool.load_popover.utilization_desc_1"),
        utilization_desc_2: t("pool_tool.load_popover.utilization_desc_2"),
        utilization_text_outOf: t("pool_tool.load_popover.utilization_text_outOf"),
        utilization_text_days: t("pool_tool.load_popover.utilization_text_days"),
        utilization_start_date: t("pool_tool.load_popover.utilization_start_date"),
        location_alias_description: t("pool_tool.load_popover.location_alias_description"),
        availability_desc_header_trusted: t("pool_tool.load_popover.availability_desc_header_trusted"),
        availability_desc_header_intern: t("pool_tool.load_popover.availability_desc_header_intern"),
        availability_desc_header_all: t("pool_tool.load_popover.availability_desc_header_all"),
        availability_desc_header_extern: t("pool_tool.load_popover.availability_desc_header_extern"),
        availability_desc_text_trusted: t("pool_tool.load_popover.availability_desc_text_trusted"),
        availability_desc_text_intern: t("pool_tool.load_popover.availability_desc_text_intern"),
        availability_desc_text_all: t("pool_tool.load_popover.availability_desc_text_all"),
        availability_desc_text_extern: t("pool_tool.load_popover.availability_desc_text_extern"),
        legend_otherReason_text: t("pool_tool.show.legend_otherReason_text"),
        legend_ownEmployee_text: t("pool_tool.show.legend_ownEmployee_text"),
        legend_trustedCompany_text: t("pool_tool.show.legend_trustedCompany_text"),
        legend_anyCompany_text: t("pool_tool.show.legend_anyCompany_text"),
        tx_offset: Transaction::TX_OFFSET,

        pool_tool_preferences: {
          pooltool_user_has_to_give_back_device: @current_user.has_to_give_back_device?(@current_community),
          pool_tool_modify_past: @current_user.is_allowed_to_book_in_past?,
          show_device_owner_per_default: Maybe(@current_user.get_company.company_option).show_device_owner_per_default.or_else(false),
          show_device_location_per_default: Maybe(@current_user.get_company.company_option).show_device_location_per_default.or_else(false)

        }
      })
    end
end
