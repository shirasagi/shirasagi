class MailPage::Agents::Nodes::PageController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  before_action :accept_cors_request, only: [:rss]
  protect_from_forgery except: [:mail]

  def pages
    MailPage::Page.public_list(site: @cur_site, node: @cur_node, date: @cur_date)
  end

  def index
    @items = pages.
      order_by(@cur_node.sort_hash).
      page(params[:page]).
      per(@cur_node.limit)

    render_with_pagination @items
  end

  def rss
    @items = pages.
      order_by(released: -1).
      limit(@cur_node.limit)

    render_rss @cur_node, @items
  end

  def mail
    if request.get? || request.head?
      head :ok
      return
    end

    begin
      Cms::ApiToken.authenticate(request, @cur_site)
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
