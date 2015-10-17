class InfosController < ApplicationController

  skip_filter :check_confirmations_and_verifications

  def about
    @selected_tribe_navi_tab = "about"
    @selected_left_navi_link = "about"
  end

  def terms
    @selected_tribe_navi_tab = "about"
    @selected_left_navi_link = "terms"
  end

  def privacy
    @selected_tribe_navi_tab = "about"
    @selected_left_navi_link = "privacy"
  end
end
