class Cms::LinkChecker
  include ActiveModel::Model

  DEFAULT_HEAD_REQUEST_TIMEOUT = 5

  attr_accessor :cur_user, :root_url
  attr_writer :fs_url, :head_request_timeout, :max_redirection, :http_basic_authentication

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

  def http_basic_authentication
    return @http_basic_authentication if instance_variable_defined?(:@http_basic_authentication)
    @http_basic_authentication = SS::MessageEncryptor.http_basic_authentication
  end

  def check_url(full_url)
    full_url = to_addressable(full_url)

    site = find_site(full_url)
    if site.blank?
      return get_http(full_url)
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
    contents_env[::Rack::Request::HTTP_X_FORWARDED_HOST] = site.domain
    contents_env["ss.site"] = site

    contents_status, _contents_headers, _contents_body = Rails.application.call(contents_env)
    case contents_status
    when 200
      {
        code: 200,
        redirection: 0
      }
    else
      {
        code: 0,
        message: I18n.t("errors.messages.link_check_failed_not_found"),
        redirection: 0
      }
    end
  end

  private

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

  def get_http(addressable_full_url)
    progress_data_size = nil
    redirection = 0

    begin
      opts = {
        redirect: false,
        http_basic_authentication: http_basic_authentication,
        progress_proc: ->(size) do
          progress_data_size = size
          raise "200"
        end
      }

      Timeout.timeout(head_request_timeout) do
        OpenURI.open_uri(addressable_full_url.to_s, **opts) { |io| io.read }
      end

      return {
        code: 200,
        redirection: redirection
      }
    rescue OpenURI::HTTPRedirect => e
      if redirection >= max_redirection
        return {
          code: 0,
          message: I18n.t("errors.messages.link_check_failed_redirection"),
          redirection: redirection
        }
      else
        redirection += 1
        addressable_full_url = to_addressable(e.uri)
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
