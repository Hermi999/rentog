class DownloadListingAttachmentJob < Struct.new(:url, :listing)

  def perform
    # Download the original image
    listing_attachment = ListingAttachment.new({listing_id: listing.id, author_id: listing.author_id})
    listing_attachment.attachment = URI.parse(url)

    if listing_attachment.save
      # wah: Add attachment to listing
      listing.listing_attachments << listing_attachment
    else
      if listing_attachment.errors && listing_attachment.errors.first[0] != :attachment_content_type
        if listing_attachment.errors.first[0] == :max_upload_limit
          flash[:error] = t("layouts.notifications.listing_attachment_max_upload_limit").html_safe
        elsif listing_attachment.errors.first[0] == :user_tried_to_hack_user_plan
          flash[:error] = t("layouts.notifications.listing_attachment_userplan_error", link: get_wp_url("pricing")).html_safe
        else
          flash[:error] = listing_attachment.errors.first[1]
        end
      else
        flash[:error] = t("layouts.notifications.listing_attachment_error")
      end

      return false
    end
  end
end
