class Cms::Line::Service::Processor::Api < Cms::Line::Service::Processor::Base
  def logger
    @logger ||= Logger.new(log_path, 'daily')
  end

  def url
    service.api_url
  end

  def log_path
    ::File.join(Rails.root, "log", service.api_log_filename)
  end

  def call
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
