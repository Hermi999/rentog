class HelpController < ApplicationController

  skip_filter :check_confirmations_and_verifications

  def how_to_use
    @selected_tribe_navi_tab = "about"
    @selected_left_navi_link = "how_to_use"
    if @community_customization && !@community_customization.how_to_use_page_content.nil?
      content = @community_customization.how_to_use_page_content.html_safe
    else
      content = MarketplaceService::API::Marketplaces::Helper.how_to_use_page_default_content(I18n.locale, @current_community.name(I18n.locale))
    end
    render locals: { how_to_use_content: content }
  end

  def faq
    @selected_tribe_navi_tab = "help"
    @selected_left_navi_link = "faq"
    gon.push({
      show_all: t("layouts.help.faq_default_page.show_all"),
      hide_all: t("layouts.help.faq_default_page.hide_all")
    })
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
