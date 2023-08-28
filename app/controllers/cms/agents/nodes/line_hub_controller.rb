class Cms::Agents::Nodes::LineHubController < ApplicationController
  include Cms::NodeFilter::View

  protect_from_forgery except: [:index, :mail]

  public

  def index
    head :ok
  end

  def line
    service = Cms::Line::Service::Group.site(@cur_site).active_group
    if !service
      Rails.logger.error("service not registered")
      raise "400"
    end

    processor = service.processor(@cur_site, @cur_node, @cur_site.line_client, request)
    processor.parse_request

    if !processor.valid_signature?
      Rails.logger.error("invalid line request")
      raise "400"
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
    item = Cms::Line::Service::Hook::ImageMap.site(@cur_site).find(params[:id]) rescue nil
    raise "404" unless item

    size = params[:size]
    raise "404" unless %w(1040 700 460 300 240).include?(size)

    image = item.try("image#{size}")
    raise "404" unless image

    send_file image.path, type: image.content_type, filename: size, x_sendfile: true
  end

  def mail
    item = Cms::Line::MailHandler.site(@cur_site).and_enabled.find_by(filename: params[:filename]) rescue nil
    raise "404" unless item

    if request.get? || request.head?
      head :ok
      return
    end

    begin
      Cms::ApiToken.authenticate(request, site: @cur_site) do |audience|
        if !Cms::Line::Message.allowed?(:edit, audience, site: @cur_site)
          raise "not allowed create line message!"
        end
      end
    rescue => e
      Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      raise "404"
    end

    data = params.permit(:data)[:data]
    raise "404" if data.blank?

    item.handle_message(data)
    head :ok
  end
end
