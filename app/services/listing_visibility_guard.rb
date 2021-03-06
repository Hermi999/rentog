#
# Give `listing`, `community` and `user` and get back true or false
# whether of not the listing can be shown to given user in the given community
#
class ListingVisibilityGuard

  def initialize(listing, community, user)
    @listing = listing
    @community = community
    @user = user
  end

  def visible?
     authorized_to_view? && (open? || is_author? || Maybe(@user).has_admin_rights_in?(@community).or_else(false) || Maybe(@user).is_supervisor_of?(@listing.author).or_else(false))
  end

  def authorized_to_view?
    return false unless listing_belongs_to_community?

    if user_logged_in? && user_member_of_community? && public_listing?
      true
    else
      if public_listing?
        public_community?

      elsif trusted_listing?
        user_and_listing_belong_to_same_company? || listing_author_follows_users_company? || @user.is_supervisor_of?(@listing.author)
      else
        user_and_listing_belong_to_same_company? || Maybe(@user).is_supervisor_of?(@listing.author).or_else(nil)
      end
    end
  end

  private

  def open?
    !@listing.closed?
  end

  def listing_belongs_to_community?
    @community && @listing.community_id == @community.id
  end

  def user_logged_in?
    !@user.nil?
  end

  def user_member_of_community?
    @user.communities.include?(@community)
  end

  def public_community?
    !@community.private?
  end

  def is_author?
    @user == @listing.author
  end

  def public_listing?
    @listing.availability != "intern" && @listing.availability != "trusted"
  end

  def trusted_listing?
    @listing.availability == "trusted"
  end

  def listing_author_follows_users_company?
    return false if @user.nil?
    @listing.author.follows?(@user.get_company)
  end

  def user_and_listing_belong_to_same_company?
    return false if @user.nil?
    @listing.person_belongs_to_same_company?(@user)
  end
end
