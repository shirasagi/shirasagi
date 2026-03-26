class Cms::LinkChecker
  include ActiveModel::Model

  DEFAULT_HEAD_REQUEST_TIMEOUT = 5

  attr_accessor :cur_user, :root_url, :fetch_content
  # attr_writer :fs_url, :head_request_timeout, :max_redirection, :http_basic_authentication
  attr_writer :fs_url, :head_request_timeout, :max_redirection

  Redirection = Data.define(:count, :visited) do
    def initialize(count: 0, visited: Set.new)
      super
    end

    def increment
      with(count: count + 1)
    end
  end

  Result = Data.define(:result, :error_code, :redirection_count, :content_type, :content) do
    def self.success(redirection_count:, content_type:, content:)
      new(
        result: :success, error_code: nil, redirection_count: redirection_count,
        content_type: content_type, content: content)
    end

    def self.error(error_code:, redirection_count:)
      new(result: :error, error_code: error_code, redirection_count: redirection_count, content_type: nil, content: nil)
    end

    def success?
      result == :success
    end

    def error?
      !success?
    end

    def message
      if error_code
        I18n.t("errors.messages.#{error_code}")
      end
    end

    def content_mime_type
      if content_type
        Mime::Type.lookup(content_type.downcase)
      end
    end
  end

  def fs_url
    return @fs_url if instance_variable_defined?(:@fs_url)

    if root_url
      @fs_url = ::File.join(root_url, "/fs/")
    else
      @fs_url = nil
    end
  end

  def head_request_timeout
    return @head_request_timeout if instance_variable_defined?(:@head_request_timeout)

    @head_request_timeout = SS.config.cms.check_links["head_request_timeout"]
    @head_request_timeout ||= DEFAULT_HEAD_REQUEST_TIMEOUT
  end

  def max_redirection
    return @max_redirection if instance_variable_defined?(:@max_redirection)
    @max_redirection = SS.config.cms.check_links["max_redirection"].to_i
  end

  # この設定は自サイトに向けてのもの。自サイトは Rails routing で解決するようにしたので HTTP アクセスは発生しないので不要となった
  # def http_basic_authentication
  #   return @http_basic_authentication if instance_variable_defined?(:@http_basic_authentication)
  #   @http_basic_authentication = SS::MessageEncryptor.http_basic_authentication
  # end

  def check_url(full_url, redirection: nil)
    full_url = to_addressable(full_url)
    redirection ||= Redirection.new

    site = find_site(full_url)
    if site.blank?
      return get_http(full_url, redirection: redirection)
    end

    if generated_file_path = get_generated_file_path(site, full_url)
      return Result.success(
        redirection_count: redirection.count, content_type: "text/html; charset=UTF-8", content: File.read(generated_file_path))
    end

    # retrieve internal page
    if fs_path?(full_url)
      full_url = append_access_token_if_possible(full_url)
    end

    contents_env = {}
    contents_env["REQUEST_URI"] = full_url.to_s
    contents_env[::Rack::PATH_INFO] = full_url.path
    contents_env[::Rack::REQUEST_METHOD] = ::Rack::GET
    contents_env[::Rack::REQUEST_PATH] = full_url.path
    contents_env[::Rack::QUERY_STRING] = full_url.query || ""
    contents_env[::Rack::RACK_ERRORS] = $stderr
    #contents_env[::Rack::RACK_INPUT] = StringIO.new("")
    contents_env[::Rack::Request::HTTP_X_FORWARDED_HOST] = site.domain
    contents_env["ss.site"] = site

    contents_status, contents_headers, contents_body = Rails.application.call(contents_env)
    case contents_status
    when 200
      if fetch_content
        content_type = contents_headers["content-type"]

        content = ""
        contents_body.each { content += _1 }
      end
      Result.success(
        redirection_count: redirection.count, content_type: content_type, content: content)
    else
      Result.error(error_code: :link_check_failed_not_found, redirection_count: redirection.count)
    end
  rescue SS::ForbiddenError
    Result.error(error_code: :link_check_failed_unauthorized, redirection_count: redirection.count)
  rescue SS::NotFoundError
    Result.error(error_code: :link_check_failed_not_found, redirection_count: redirection.count)
  rescue => e
    Rails.logger.error { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    raise
  end

  def to_addressable(full_url)
    full_url = Addressable::URI.parse(full_url) unless full_url.is_a?(Addressable::URI)
    full_url.normalize
  end

  def find_site(addressable_full_url)
    @internal_domain_set ||= begin
      domains = Cms::Site.without_deleted.pluck(:domains)
      domains.flatten!
      domains.select!(&:present?)
      Set.new(domains)
    end

    return unless @internal_domain_set.include?(addressable_full_url.authority)
    Cms::Site.without_deleted.find_by_domain(addressable_full_url.authority, addressable_full_url.path)
  end

  def get_http(addressable_full_url, redirection:)
    proxy_options = SS::ProxySetting.instance.faraday_proxy_options
    ssl_options = SS::ProxySetting.instance.faraday_ssl_options
    faraday_options = { url: addressable_full_url.origin, request: { timeout: head_request_timeout } }
    faraday_options[:proxy] = proxy_options if proxy_options.present?
    faraday_options[:ssl] = ssl_options if ssl_options.present?
    http_client = Faraday.new(faraday_options) do |builder|
      builder.request :url_encoded
      # Basic 認証設定は自サイトに向けてのもの。
      # 自サイトは Rails routing で解決するようにしたので HTTP アクセスは発生しないので不要となった
      # if http_basic_authentication.present?
      #   builder.request :authorization, :basic, *http_basic_authentication
      # end
      builder.response :logger, Rails.logger
      builder.adapter Faraday.default_adapter
    end
    http_client.headers[:user_agent] += " (SHIRASAGI/#{SS.version}; PID/#{Process.pid})"
    http_client.headers[:accept_encoding] = "gzip"

    begin
      resp = http_client.head(addressable_full_url.request_uri)
    ensure
      redirection.visited.add(addressable_full_url.to_s)
    end
    if resp.success?
      content_type = resp.headers['Content-Type']
      return Result.success(redirection_count: redirection.count, content_type: content_type, content: nil)
    end

    redirect_to = resp.headers['Location']
    if redirect_to.present?
      if redirection.count >= max_redirection
        return Result.error(error_code: :link_check_failed_redirection, redirection_count: redirection.count + 1)
      else
        if redirection.visited.include?(redirect_to)
          return Result.error(error_code: :link_check_failed_cyclic_redirection, redirection_count: redirection.count + 1)
        end

        return check_url(redirect_to, redirection: redirection.increment)
      end
    end

    if resp.status == 401
      error_code = :link_check_failed_unauthorized
    else
      error_code = :link_check_failed_not_found
    end
    Result.error(error_code: error_code, redirection_count: redirection.count)
  rescue OpenSSL::SSL::SSLError, Faraday::SSLError
    return Result.error(
      error_code: :link_check_failed_certificate_verify_failed, redirection_count: redirection.count)
  rescue Timeout::Error, Faraday::TimeoutError
    return Result.error(error_code: :link_check_failed_timeout, redirection_count: redirection.count)
  rescue => e
    Rails.logger.error { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    error_code = :link_check_failed_not_found
    Result.error(error_code: error_code, redirection_count: redirection.count)
  end

  def get_generated_file_path(site, addressable_full_url)
    path = "#{site.root_path}#{addressable_full_url.path}"
    path = File.join(path, "index.html") if Fs.directory?(path)
    return path if Fs.file?(path)

    path = Addressable::URI.unencode(path)
    return path if Fs.file?(path)

    nil
  end

  def fs_path?(addressable_full_url)
    fs_url && addressable_full_url.to_s.start_with?(fs_url)
  end

  def append_access_token_if_possible(addressable_full_url)
    return addressable_full_url unless cur_user

    token = SS::AccessToken.new(cur_user: cur_user)
    token.create_token
    return addressable_full_url unless token.save

    query_values = addressable_full_url.query_values
    query_values ||= {}
    query_values["access_token"] = token.token

    addressable_full_url.query_values = query_values
    addressable_full_url
  end
end
