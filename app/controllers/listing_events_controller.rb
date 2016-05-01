class ListingEventsController < ApplicationController

  before_filter :ensure_is_authorized_to_view


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


  private

    def ensure_is_authorized_to_view
      @author = Person.where(:username => params['person_id']).first

      # ALLOWED
        return if @current_user.get_company == @author

      # NOT ALLOWED
        # with error message
        flash[:error] = t("listing_events.you_have_to_be_company_member")
        redirect_to root
        return false
    end
end
