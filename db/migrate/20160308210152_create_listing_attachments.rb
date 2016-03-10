class CreateListingAttachments < ActiveRecord::Migration
  def self.up
    create_table :listing_attachments do |t|
      t.integer :listing_id
      t.string :author_id
      t.string :attachment_file_name
      t.string :attachment_content_type
      t.integer :attachment_file_size
      t.datetime :attachment_updated_at

      t.timestamps null: false
    end
  end

  def self.down
    drop_table :listing_attachments
  end

end
