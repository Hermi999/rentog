class ImportListingsController < ApplicationController
  def new_import
  end

  def upload_import_file
    unless save_import_file(params)
      redirect_to import_listings_new_import_path and return
    end

  end

  def show_import_delta
  end

  def create_listings_from_file
  end


  private
    def save_import_file(params)
      return false if params[:import_file].nil?

      # wah: Store & Remove attachment from params hash
      import_file = params[:import_file][:file]

      # wah: Create new attachment object
      @attachment = ImportListingsFile.new
      @attachment.attachment = import_file[0]
      @attachment.author_id = @current_user.id

      if @attachment.save
        # wah: Add import file to person
        @current_user.import_listings_file << @attachment
      else
        if @attachment.errors && @attachment.errors.first[0] != :attachment_content_type
          if @attachment.errors.first[0] == :max_upload_limit
            flash[:error] = t("layouts.notifications.listing_attachment_max_upload_limit").html_safe
          else
            flash[:error] = @attachment.errors.first[1]
          end
        else
          flash[:error] = t("layouts.notifications.import_listings_file_error")
        end

        return false
      end
      return true
    end

end
