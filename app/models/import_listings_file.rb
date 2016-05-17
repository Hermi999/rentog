# == Schema Information
#
# Table name: import_listings_files
#
#  id                      :integer          not null, primary key
#  author_id               :string(255)
#  importfile_file_name    :string(255)
#  importfile_content_type :string(255)
#  importfile_file_size    :integer
#  importfile_updated_at   :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

class ImportListingsFile < ActiveRecord::Base
  belongs_to :author, :class_name => "Person"

  has_attached_file :importfile
  process_in_background :importfile

  validates_attachment_presence :importfile
  validates_attachment_size :importfile, :less_than => 2.megabytes
  validates_attachment_content_type :importfile, :content_type => ["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]


  # Restrict maximum upload amount
  validate :max_user_importFile_size

  private

    def max_user_importFile_size
      file = ImportListingsFile.where(author_id: author_id)

      # sum the amount of data a user has uploaded
      fileSize = 0
      file.each do |f|
        fileSize += f.importfile_file_size
      end

      # If bigger than 1 GB
      if (fileSize/(1024*1024) > (1*1024))
        errors.add(:max_upload_limit, "User uploaded more then 1GB import files (xlsx)")
      end
    end

end

