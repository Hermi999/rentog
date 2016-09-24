class Admin::UploadPerJsonController < ApplicationController

  before_filter :ensure_is_admin

  def new
  end

end
