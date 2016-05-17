class ChangeColumnNamesOfImportListingsFile < ActiveRecord::Migration
  def change
    rename_column :import_listings_files, :attachment_file_name, :importfile_file_name
    rename_column :import_listings_files, :attachment_content_type, :importfile_content_type
    rename_column :import_listings_files, :attachment_file_size, :importfile_file_size
    rename_column :import_listings_files, :attachment_updated_at, :importfile_updated_at
  end
end
