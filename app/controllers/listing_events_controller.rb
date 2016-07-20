class ListingEventsController < ApplicationController

  before_filter :ensure_is_authorized_to_view, only: [:show, :getMoreListingEvents]
  before_filter :ensure_is_admin, only: [:export]

  # shown in 'device event history'
  def show
    @company_listing_ids_with_titles = [""]
    @listing_images = {}

    search = {
        author_id: @author.id,
        include_closed: true,
        page: 1,
        per_page: 1000
      }

      includes = [:author, :listing_images]
      company_listings = ListingIndexService::API::Api.listings.search(community_id: @current_community.id, search: search, includes: includes).and_then { |res|
        Result::Success.new(
          ListingIndexViewUtils.to_struct(
          result: res,
          includes: includes,
          page: search[:page],
          per_page: search[:per_page],
        ))
      }.data

      company_listings.each do |listing|
        @company_listing_ids_with_titles << [listing.title, listing.id]
        @listing_images[listing.id] = listing.listing_images.first.small_3x2 if listing.listing_images != []
      end

      render :show, :locals => { :listing_id => params[:listing_id] }
  end


  def getMoreListingEvents
    respond_to do |format|
      format.js { render :partial => "timeline_block", :locals => { :offset => params[:offset], :listing_id => params[:listing_id] } and return }
    end
  end

  # export for admin page
  def export
    @listing_events = ListingEvent.all.order('created_at DESC').limit(100000)

    # create new export file
    @p = Axlsx::Package.new
    @wb = @p.workbook

    # worksheet devices
    @wb.add_worksheet(:name => "Listing Events") do |sheet|
      sheet.add_row ListingEvent.new.attributes.keys

      @listing_events.each do |row|
        new_row = row.as_json.map do |field|
          field[1].to_s
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
      @author = Person.where(:username => params['person_id']).first
      @is_member_of_company = @relation == :company_admin_own_site || @relation == :company_employee || @relation == :rentog_admin_own_site

      # ALLOWED
        return if @relation == :rentog_admin ||
                  @relation == :rentog_admin_own_site ||
                  @relation == :domain_supervisor ||
                  @relation == :company_admin_own_site

      # NOT ALLOWED
        # with error message
        flash[:error] = t("listing_events.you_have_to_be_company_member")
        redirect_to root
        return false
    end
end
