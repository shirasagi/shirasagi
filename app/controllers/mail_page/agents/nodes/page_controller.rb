class MailPage::Agents::Nodes::PageController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::NodeFilter::ListView

  protect_from_forgery except: [:mail]

  private

  def pages
    MailPage::Page.public_list(site: @cur_site, node: @cur_node, date: @cur_date)
  end

  public

  def mail
    if request.get? || request.head?
      head :ok
      return
    end

    begin
      Cms::ApiToken.authenticate(request, site: @cur_site) do |audience|
        if !MailPage::Page.allowed?(:edit, audience, site: @cur_site, node: @cur_node)
          raise "not allowed create mail page!"
        end
      end
    rescue => e
      Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      raise "404"
    end

    data = params.permit(:data)[:data]
    raise "404" if data.blank?

    file = SS::MailHandler.write_eml(data, "mail_page")
    MailPage::ImportJob.bind(site_id: @cur_site.id).perform_now(file)
    head :ok
  end
end
