class Cms::Line::Service::Processor::GdChat < Cms::Line::Service::Processor::Base
  def logger
    Pippi::GdChat.logger
  end

  def call
    url = SS.config.pippi.dig("gd_chat", "webhook_url")
    path = URI.parse(url).path
    base_url = url.sub(path, "")

    http_client = Faraday.new(url: base_url)
    res = http_client.post do |req|
      req.url path
      req.headers["Content-Type"] = request.headers["CONTENT_TYPE"]
      req.headers["x-line-signature"] = signature
      req.body = body
    end

    logger.info "### #{res.headers["date"]} ###"
    logger.info "request headers: #{res.env.request_headers}"
    logger.info "request body: #{body}"
    logger.info "response status: #{res.status}"
    logger.info "response body: #{res.body}"
    logger.info ""
  end
end
