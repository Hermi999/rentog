class HelpController < ApplicationController

  skip_filter :check_confirmations_and_verifications

  def how_to_use
    @selected_tribe_navi_tab = "about"
    @selected_left_navi_link = "how_to_use"
    case(how_to_use_content?)
    when None, Some(false)
      raise ActiveRecord::RecordNotFound
    else
      render locals: { how_to_use_content: @community_customization.how_to_use_page_content }
    end
  end

  def faq
    @selected_tribe_navi_tab = "help"
    @selected_left_navi_link = "faq"
  end

  def pool_tool
    @selected_tribe_navi_tab = "help"
    @selected_left_navi_link = "pool_tool"
  end


  private

    def how_to_use_content?
      Maybe(@community_customization).map { |customization| !customization.how_to_use_page_content.nil? }
    end
end
