class Cms::Agents::Nodes::LineHubController < ApplicationController
  include Cms::NodeFilter::View

  protect_from_forgery except: [:index]

  public

  def index
    service = Cms::Line::Service::Group.site(@cur_site).active_group
    if !service
      Rails.logger.error("service not registered")
      head :bad_request
      return
    end

    processor = service.processor(@cur_site, @cur_node, @cur_site.line_client, request)
    processor.parse_request

    if !processor.valid_signature?
      Rails.logger.error("invalid line request")
      head :bad_request
      return
    end

    if processor.webhook_verify_request?
      head :ok
      Rails.logger.info("verified line request")
      return
    end

    processor.call
    head :ok
  end

  def image_map
    item = Cms::Line::Service::Hook::ImageMap.find(params[:id]) rescue NodeFilter
    raise "404" unless item

    size = params[:size]
    raise "404" unless %w(1040 700 460 300 240).include?(size)

    image = item.try("image#{size}")
    raise "404" unless image

    send_file image.path, type: image.content_type, filename: size, x_sendfile: true
  end
end
