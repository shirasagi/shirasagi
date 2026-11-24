#frozen_string_literal: true

module Opendata
  module_function

  REDIRECT_STATUS_CODES = Cms::PublicFilter::REDIRECT_STATUS_CODES
  DEFAULT_HEAD_REQUEST_TIMEOUT = 30
  DEFAULT_MAX_DOWNLOAD_SIZE = 10 * 1_024 * 1_024
  DEFAULT_MAX_REDIRECTION = 3

  DEFLATE_CHUNK_SIZE = 8 * 1_024

  mattr_accessor :ssrf_resolver, instance_accessor: false

  def head_request_timeout
    return @head_request_timeout if instance_variable_defined?(:@head_request_timeout)

    head_request_timeout = SS.config.opendata.head_request_timeout
    if head_request_timeout.numeric?
      @head_request_timeout = head_request_timeout.to_i
    end
    @head_request_timeout ||= DEFAULT_HEAD_REQUEST_TIMEOUT
  end

  def max_download_size
    return @max_download_size if instance_variable_defined?(:@max_download_size)

    max_download_size = SS.config.opendata.max_download_size
    if max_download_size.numeric?
      @max_download_size = max_download_size.to_i
    end
    @max_download_size ||= DEFAULT_MAX_DOWNLOAD_SIZE
  end

  def max_redirection
    return @max_redirection if instance_variable_defined?(:@max_redirection)

    max_redirection = SS.config.opendata.max_redirection
    if max_redirection.numeric?
      @max_redirection = max_redirection.to_i
    end
    @max_redirection ||= DEFAULT_MAX_REDIRECTION
  end

  def ssrf_allow_list
    return @ssrf_allow_list if instance_variable_defined?(:@ssrf_allow_list)
    @ssrf_allow_list = Array(SS.config.opendata.ssrf_allow_list).flatten.select(&:present?).uniq.freeze
  end

  def ssrf_deny_list
    return @ssrf_deny_list if instance_variable_defined?(:@ssrf_deny_list)
    @ssrf_deny_list = Array(SS.config.opendata.ssrf_deny_list).flatten.select(&:present?).uniq.freeze
  end

  def download_url!(url, redirection: nil, timeout: nil)
    url = url.to_str
    url = Addressable::URI.parse(url) unless url.is_a?(Addressable::URI)
    redirection ||= Cms::LinkChecker::Redirection.new
    timeout ||= Opendata.head_request_timeout

    Timeout.timeout(timeout) do
      http_client = new_http_client(url, timeout)

      temp_file = Tempfile.open('temp')
      temp_file.binmode
      total_size = 0

      resp = http_client.get do |req|
        req.options.on_data = proc do |chunk, overall_received_bytes|
          raise SS::NotFoundError, "#{url}: file size is too large" if total_size + overall_received_bytes > max_download_size

          total_size += overall_received_bytes
          temp_file.write chunk
        end
      end

      if REDIRECT_STATUS_CODES.include?(resp.status)
        redirect_to = resp.headers['Location']
        raise SS::NotFoundError, "#{url}: got redirect response but location is not found" if redirect_to.blank?
        raise SS::NotFoundError, "#{url}: too many redirections" if redirection.count >= Opendata.max_redirection

        redirect_to = Addressable::URI.join(url, redirect_to)
        raise SS::NotFoundError, "#{url}: unsafe redirect" unless safe_redirect?(url, redirect_to)

        return download_url!(redirect_to, redirection: redirection.increment, timeout: timeout)
      end

      raise SS::NotFoundError, "#{url}: failed to download" unless resp.success?

      temp_file.rewind
      temp_file = inflate_if_necessary(temp_file, resp.headers['content-encoding'])

      filename = Opendata.extract_filename(resp.headers['content-disposition'])
      filename ||= File.basename(url.path)

      last_modified = resp.headers['last-modified']
      if last_modified
        last_modified = last_modified.in_time_zone
      else
        last_modified = Time.zone.now
      end

      temp_file = ActionDispatch::Http::UploadedFile.new(
        tempfile: temp_file, filename: filename, type: SS::MimeType::DEFAULT_MIME_TYPE)

      [ temp_file, last_modified ]
    rescue
      temp_file.close(true) if temp_file
      raise
    end
  end

  def new_http_client(url, timeout)
    proxy_options = SS::ProxySetting.instance.faraday_proxy_options
    ssl_options = SS::ProxySetting.instance.faraday_ssl_options
    faraday_options = { url: url, request: { timeout: timeout } }
    faraday_options[:proxy] = proxy_options if proxy_options.present?
    faraday_options[:ssl] = ssl_options if ssl_options.present?
    ssrf_filter_options = {}
    ssrf_filter_options[:allowlist] = Opendata.ssrf_allow_list if Opendata.ssrf_allow_list.present?
    ssrf_filter_options[:denylist] = Opendata.ssrf_deny_list if Opendata.ssrf_deny_list.present?
    ssrf_filter_options[:resolver] = Opendata.ssrf_resolver if Opendata.ssrf_resolver.present?
    http_client = Faraday.new(faraday_options) do |builder|
      builder.request :url_encoded
      builder.request :ssrf_filter, **ssrf_filter_options
      builder.response :logger, Rails.logger
      builder.adapter Faraday.default_adapter
    end
    http_client.headers[:user_agent] = http_client.headers[:user_agent].to_s + " (SHIRASAGI/#{SS.version}; PID/#{Process.pid})"
    http_client.headers[:accept_encoding] = "deflate,gzip"
    http_client
  end

  def safe_redirect?(from_url, to_url)
    return true if from_url.scheme.downcase != "https"
    to_url.scheme.downcase == "https"
  end

  def inflate_if_necessary(temp_file, content_encoding)
    return temp_file if content_encoding.blank?

    case content_encoding.strip.downcase
    when "gzip"
      temp_file2 = Tempfile.open('temp')
      temp_file2.binmode

      Zlib::GzipReader.wrap(temp_file) do |source|
        IO.copy_stream(source, temp_file2)
      end

      temp_file.close(true)
      temp_file2
    when "deflate"
      inflater = Zlib::Inflate.new
      temp_file2 = Tempfile.open('temp')
      temp_file2.binmode

      loop do
        chunk = temp_file.read(DEFLATE_CHUNK_SIZE)
        break unless chunk

        out = inflater.inflate(chunk)
        temp_file2.write(out)
      end

      out = inflater.finish
      temp_file2.write(out)

      inflater.close
      temp_file.close(true)
      temp_file2
    else
      raise SS::NotFoundError, "#{content_encoding} not supported"
    end
  end

  def extract_filename(content_disposition)
    return if content_disposition.blank?

    # SJIS の2バイト目には 0x5C (\) が現れるため、解析前に UTF-8 へ変換する
    content_disposition = NKF.nkf("-w -x -m0", content_disposition)
    if (matched = content_disposition.match(/;\s*filename\*\s*=\s*"?UTF-8'[^']*'([^;"\s]+)/i))
      filename = URI.decode_uri_component(matched[1]) rescue nil
      filename = nil unless filename&.valid_encoding?
    end
    if filename.blank? && (matched = content_disposition.match(/;\s*filename\s*=\s*(?:"((?:\\.|[^"\\])*)"|([^;]+))/i))
      filename = matched[1] ? matched[1].gsub(/\\(.)/, '\1') : matched[2].strip
    end
    return if filename.blank?

    filename = filename.tr("\\", "/").gsub(/[[:cntrl:]]/, "")
    filename = ::File.basename(filename)
    filename unless [ "", ".", "..", "/" ].include?(filename)
  end
end
