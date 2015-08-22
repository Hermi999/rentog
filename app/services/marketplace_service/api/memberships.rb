module MarketplaceService::API

  module Memberships

    module_function

    def make_user_a_member_of_community(user_id, community_id, invitation_id=nil)

      # Fetching the models would not be necessary, but that validates the ids
      user = Person.find(user_id)
      community = Community.find(community_id)

      membership = CommunityMembership.new(:person => user, :community => community, :consent => community.consent)
      membership.status = "pending_email_confirmation"
      membership.invitation = Invitation.find(invitation_id) if invitation_id.present?

      # If the community doesn't have any members, make the first one an admin
      # wah82wi: Also make the user "superadmin", because he needs to set the
      # Braintree Payment API keys.
      # Furthermore set the organization_name to a value, because otherwise
      # in an organization-only marketplace the for the name of the first admin
      # nothing is shown
      if community.members.count == 0
        user.update_attribute :organization_name, "Administrator"
        user.update_attribute :is_admin, true
        membership.admin = true
        membership.status = "accepted"
      end
      membership.save!
    end

  end
end
