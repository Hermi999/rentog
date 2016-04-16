class ChooseProductController < ApplicationController
  def choose_product
    # def show
  end

  def update_main_product
    if @current_user && @current_user.is_organization
      if params[:product] == "pooltool"
        @current_user.update_attribute(:main_product, "pooltool")
      elsif params[:product] == "marketplace"
        @current_user.update_attribute(:main_product, "marketplace")
      end
      redirect_to root and return

    else
      flash[:error] = "This action is only allowed to logged in company admins"
      redirect_to root and return
    end
  end
end
