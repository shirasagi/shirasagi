class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, if: ->{ !protect_csrf? }

  #before_action -> { FileUtils.touch "#{Rails.root}/Gemfile" } if Rails.env.to_s == "development"
  before_action :set_cache_buster

  def t(key, opts = {})
    opts[:scope] = [:views] if key !~ /\./ && !opts[:scope]
    I18n.t key, opts.merge(default: key.to_s.humanize)
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
    headers['Cache-Control'] = 'no-cache'
    headers['Transfer-Encoding'] = 'chunked'
    headers.delete('Content-Length')

    # output csv by streaming
    self.response_body = Rack::Chunked::Body.new(enum)
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
      request.env["HTTP_X_REAL_IP"] || request.remote_addr
    end

    def browser
      require "browser"
      Browser.new(request.user_agent, accept_language: request.accept_language)
    end

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
        render text: ""
      end
    end

    def set_cache_buster
      if request.xhr?
        response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "-1"
      end
    end
end
