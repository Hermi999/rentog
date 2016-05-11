class CreateImportListingsFiles < ActiveRecord::Migration
  def self.up
    create_table :import_listings_files do |t|
      t.string :author_id
      t.string :attachment_file_name
      t.string :attachment_content_type
      t.integer :attachment_file_size
      t.datetime :attachment_updated_at

      t.timestamps null: false
    end
  end

  def self.down
    drop_table :import_listings_files
  end
end
