# == Schema Information
#
# Table name: listing_attachments
#
#  id                      :integer          not null, primary key
#  listing_id              :integer
#  author_id               :string(255)
#  attachment_file_name    :string(255)
#  attachment_content_type :string(255)
#  attachment_file_size    :integer
#  attachment_updated_at   :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

class ListingAttachment < ActiveRecord::Base
  belongs_to :listing
  belongs_to :author, :class_name => "Person"

  has_attached_file :attachment
  process_in_background :attachment

  validates_attachment_presence :attachment
  validates_attachment_size :attachment, :less_than => 15.megabytes
  validates_attachment_content_type :attachment, :content_type => ["application/pdf"]


  # Restrict maximum upload amount to account type and check for plan type
  validate :max_user_attachment_size, :user_plan_check


  private

    def max_user_attachment_size
      userAttachments = ListingAttachment.where(author_id: author_id)

      # sum the amount of data a user has uploaded
      fileSize = 0
      userAttachments.each do |attachment|
        fileSize += attachment.attachment_file_size
      end

      # If bigger than 1 GB
      if (fileSize/(1024*1024) > (1*1024))
        errors.add(:max_upload_limit, "User uploaded more then 1GB listing attachments")
      end
    end

    def user_plan_check
      listingAttachments = ListingAttachment.where(author_id: author_id, listing_id: listing_id)
      # if to many listing attachments for user plan type
      userplanservice = UserPlanService::Api.new
      if userplanservice.get_plan_feature_level(Person.where(id: author_id).first, :listing_attachments)[:value] <= listingAttachments.count
        errors.add(:user_tried_to_hack_user_plan, "User reached maximum listing attachments for his current user plan")
      end
    end
end
