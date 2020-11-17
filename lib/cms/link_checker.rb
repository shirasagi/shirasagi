class Cms::LinkChecker
  def initialize(options = {})
    @cur_user = options[:cur_user]

    if options[:root_url].present?
      @root_url = options[:root_url]
      @fs_url = ::File.join(@root_url, "/fs/")
    end

    @head_request_timeout = SS.config.cms.check_links["head_request_timeout"]
    @head_request_timeout = options[:head_request_timeout] if options[:head_request_timeout].present?

    @max_redirection = SS.config.cms.check_links["max_redirection"].to_i
    @max_redirection = options[:max_redirection].to_i if options[:max_redirection].present?

    @http_basic_authentication = SS::MessageEncryptor.http_basic_authentication
    @http_basic_authentication = options[:http_basic_authentication] if options[:http_basic_authentication].present?
  end

  def check_url(url)
    progress_data_size = nil
    redirection = 0

    begin
      url = normalize_url(url)
      proxy = ( url =~ /^https/ ) ? ENV['HTTPS_PROXY'] : ENV['HTTP_PROXY']
      opts = {
        proxy: proxy,
        redirect: false,
        http_basic_authentication: @http_basic_authentication,
        progress_proc: ->(size) do
          progress_data_size = size
          raise "200"
        end
      }

      Timeout.timeout(@head_request_timeout) do
        open(url, opts) { |_f| }
      end

      return {
        code: 200,
        redirection: redirection
      }
    rescue OpenURI::HTTPRedirect => e
      if redirection >= @max_redirection
        return {
          code: 0,
          message: I18n.t("errors.messages.link_check_failed_redirection"),
          redirection: redirection
        }
      else
        redirection += 1
        url = e.uri
        retry
      end
    rescue Addressable::URI::InvalidURIError
      return {
        code: 0,
        message: I18n.t("errors.messages.link_check_failed_invalid_link"),
        redirection: redirection
      }
    rescue OpenSSL::SSL::SSLError => e
      return {
        code: 0,
        message: I18n.t("errors.messages.link_check_failed_certificate_verify_failed"),
        redirection: redirection
      }
    rescue Timeout::Error
      return {
        code: 0,
        message: I18n.t("errors.messages.link_check_failed_timeout"),
        redirection: redirection
      }
    rescue => e
      if progress_data_size
        code = 200
        message = nil
      else
        code = 0
        if e.to_s == "401 Unauthorized"
          message = I18n.t("errors.messages.link_check_failed_unauthorized")
        else
          message = I18n.t("errors.messages.link_check_failed_not_found")
        end
      end

      return {
        code: code,
        message: message,
        redirection: redirection
      }
    end
  end

  def normalize_url(url)
    uri = ::Addressable::URI.parse(url)
    url = uri.normalize.to_s

    if @cur_user && @fs_url && url.start_with?(@fs_url)
      token = SS::AccessToken.new(cur_user: @cur_user)
      token.create_token
      if token.save
        url += uri.query.present? ? "&" : "?"
        url += "access_token=#{token.token}"
      end
    end

    url
  end
end
