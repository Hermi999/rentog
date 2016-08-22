# encoding: utf-8

include ApplicationHelper
include ListingsHelper
include TruncateHtmlHelper

# rubocop:disable ClassLength
class AdminMailer < ActionMailer::Base
  include MailUtils

  # Enable use of method to_date.
  require 'active_support/core_ext'

  require "truncate_html"

  default :from => APP_CONFIG.sharetribe_mail_from_address
  layout 'email'

  add_template_helper(EmailTemplateHelper)


  def send_kpis_to_admins(kpis, kpis2, community)
    @kpis = kpis
    @kpis2 = kpis2
    @community = community

    @url_params = {
      :host => @community.full_domain,
      :locale => "de"
    }

    premailer_mail(
        :to => @community.admin_emails + ["janel.leonor@gmail.com"],
        :from => community_specific_sender(@community),
        :subject => "Weekly Rentog KPIs")
  end


  private

    def premailer_mail(opts, &block)
      premailer(mail(opts, &block))
    end
end

