class ImportListingsController < ApplicationController
  
  before_filter :ensure_is_admin

  # render listings import page
  def new_import
  end

  # upload an import file and display the result. Highlight new listings, those who are adapted and also the errors.
  def upload_import_file
    # redirect if save file is not possible
    unless save_import_file(params)
      redirect_to import_listings_new_import_path and return
    end

    @import_listings = ImportListingsService.new file_url, @current_user, @relation
  end

  def upload_delete_file
    # redirect if save file is not possible
    unless save_import_file(params)
      redirect_to import_listings_new_import_path and return
    end

    @delete_listings = DeleteListingsService.new file_url, @current_user, @relation
  end

  # Just create listings, do not update existings listings
  def create_listings_from_file
    # create listings based on last imported file
    @import_listings = ImportListingsService.new file_url, @current_user, @relation
    @result = @import_listings.createListings(@current_user, @current_community, @relation)
    render locals: {type: "create"}
  end

  # Only update listings. Do not create new listings.
  def update_listings_from_file
    # create listings based on last imported file
    @import_listings = ImportListingsService.new file_url, @current_user, @relation
    @result = @import_listings.updateListings(@current_user, @current_community, @relation)
    render :create_listings_from_file, locals: {type: "update"}
  end

  # Update and create listings.
  def update_and_create_listings_from_file
    # create listings based on last imported file
    @import_listings = ImportListingsService.new file_url, @current_user, @relation
    @result = @import_listings.updateAndCreateListings(@current_user, @current_community, @relation)
    render :create_listings_from_file, locals: {type: "create"}
  end

  # Delete certain listings
  def delete_listings_from_file
    @delete_listings = DeleteListingsService.new file_url, @current_user, @relation
    @result = @delete_listings.deleteListings
    flash[:success] = "Successfully deleted listings!"
    render :new_import
  end


  private

    def file_url 
      file_url = 
        if Rails.env == "development"
          @current_user.import_listings_file.last.importfile.path
        else
          @current_user.import_listings_file.last.importfile.url
        end
    end

    def save_import_file(params)
      return false if params[:import_file].nil?

      # wah: Store & Remove file from params hash
      import_file = params[:import_file][:file]

      # wah: Create new file object
      @upload = ImportListingsFile.new
      @upload.importfile = import_file[0]
      @upload.author_id = @current_user.id

      if @upload.save
        # wah: Add import file to person
        @current_user.import_listings_file << @upload
      else
        if @upload.errors && @upload.errors.first[0] != :importfile_content_type
          if @upload.errors.first[0] == :max_upload_limit
            flash[:error] = t("layouts.notifications.listing_attachment_max_upload_limit").html_safe
          else
            flash[:error] = @upload.errors.first[1]
          end
        else
          flash[:error] = t("layouts.notifications.import_listings_file_error")
        end

        return false
      end
      return true
    end

end
