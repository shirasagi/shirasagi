class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, raise: false, if: ->{ !protect_csrf? }

  # before_action -> { FileUtils.touch "#{Rails.root}/Gemfile" } if Rails.env.to_s == "development"
  before_action :set_cache_buster

  before_action :clear_secure_option_of_session_on_ie11

  class CloseableChunkedBody < Rack::Chunked::Body
    def initialize(*args)
      super
      @closed = false
    end

    def each(&block)
      super
    ensure
      unless @closed
        close
        @closed = true
      end
    end

    def close
      return unless @body.respond_to?(:close)

      if @body.method(:close).arity == 0
        @body.close
      else
        # Tempfile support
        @body.close(true)
      end
    end
  end

  def new_agent(controller_name)
    agent = SS::Agent.new controller_name
    agent.controller.params  = params
    agent.controller.request = request
    agent.controller.instance_variable_set :@controller, self
    agent
  end

  def render_agent(controller_name, action)
    new_agent(controller_name).render(action)
  end

  def invoke_agent(controller_name, action)
    new_agent(controller_name).invoke(action)
  end

  def send_enum(enum, options = {})
    content_type = options.fetch(:type, DEFAULT_SEND_FILE_TYPE)
    self.content_type = content_type

    disposition = options.fetch(:disposition, DEFAULT_SEND_FILE_DISPOSITION)
    unless disposition.nil?
      disposition  = disposition.to_s
      disposition += "; filename=\"#{options[:filename]}\"" if options[:filename]
      headers['Content-Disposition'] = disposition
    end

    # nginx doc: Setting this to "no" will allow unbuffered responses suitable for Comet and HTTP streaming applications
    headers['X-Accel-Buffering'] = 'no'
    headers['Cache-Control'] = 'no-store'
    headers['Transfer-Encoding'] = 'chunked'
    headers.delete('Content-Length')

    # output csv by streaming
    self.response_body = CloseableChunkedBody.new(enum)
  end

  def send_file_headers!(options)
    if browser.ie?("<= 11") && ie11_attachment_mime_types.include?(options[:type])
      options[:disposition] = "attachment"
    end
    super(options)
  end

  def ie11_attachment_mime_types
    @_ie11_attachment_mime_types ||= begin
      mime_types = SS.config.ie11.dig("content_disposition", "attachment", "mime_type_map")
      mime_types ? mime_types.values.flatten : []
    end
  end

  def ss_send_file(file, opts = {})
    if Fs.mode == :file
      opts[:x_sendfile] = true unless opts.key?(:x_sendfile)
      send_file file, opts
    else
      send_data Fs.binread(file), opts
    end
  end

  def json_content_type
    (browser.ie? && browser.version.to_i <= 9) ? "text/plain" : "application/json"
  end

  private

  def request_host
    request.env["HTTP_X_FORWARDED_HOST"] || request.env["HTTP_HOST"] || request.host_with_port
  end

  def request_path
    request.env["REQUEST_PATH"] || request.path
  end

  def protect_csrf?
    SS.config.env.protect_csrf
  end

  def remote_addr
    request.env["HTTP_X_REAL_IP"].presence || request.remote_addr
  end

  def pc_browser?
    return @is_pc_browser if !@is_pc_browser.nil?

    platform = browser.platform
    @is_pc_browser = platform.windows? || platform.mac? || platform.linux?
  end
  helper_method :pc_browser?

  # Accepts the request for Cross-Origin Resource Sharing.
  # @return boolean
  def accept_cors_request
    if request.env["HTTP_ORIGIN"].present?
      headers["Access-Control-Allow-Origin"] = request.env["HTTP_ORIGIN"]
      headers["Access-Control-Allow-Methods"] = "POST, GET, OPTIONS"
      headers["Access-Control-Allow-Headers"] = "Content-Type, Origin, Accept"
    end

    if request.request_method == "OPTIONS"
      headers["Access-Control-Max-Age"] = "86400"
      headers["Content-Length"] = "0"
      headers["Content-Type"] = "text/plain"
      render plain: ""
    end
  end

  def set_cache_buster
    if request.xhr?
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "-1"
    end
  end

  def trusted_url?(url)
    return true if Sys::TrustedUrlValidator.url_type == 'any'

    url = ::Addressable::URI.parse(url.to_s)

    known_trusted_urls = []
    if @cur_site.present? && @cur_site.respond_to?(:domain_with_subdir)
      domain_with_subdir = @cur_site.domain_with_subdir
      if domain_with_subdir.present?
        known_trusted_urls << "//#{domain_with_subdir}"
      end
    end

    Sys::TrustedUrlValidator.valid_url?(url, known_trusted_urls)
  end
  helper_method :trusted_url?

  def trusted_url!(url)
    raise "untrusted url" unless trusted_url?(url)
    url
  end
  helper_method :trusted_url!

  def clear_secure_option_of_session_on_ie11
    return unless browser.ie?("<= 11")

    # IE11 利用時、CMS のページのプレビュー表示での印刷時に画像が表示されないという障害がある。
    # その障害は Set-Cookie レスポンスの SameSite=Lax が原因。
    # Set-Cookie レスポンスに SameSite=Lax がついていない場合、Firefox などの一部のブラウザの開発者ツールで警告が表示されるし、
    # SameSite=Lax は付いておいた方がよいので、IE11 の場合だけ無効にする。
    request.session_options[:same_site] = nil if request.session_options[:same_site].present?
  end
end
