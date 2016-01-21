class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token unless SS.config.env.protect_csrf

  #before_action -> { FileUtils.touch "#{Rails.root}/Gemfile" } if Rails.env.to_s == "development"
  before_action :set_cache_buster

  public
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

  private
    def remote_addr
      request.env["HTTP_X_REAL_IP"] || request.remote_addr
    end

    def browser
      require "browser"
      Browser.new(ua: request.user_agent, accept_language: request.accept_language)
    end

    # Accepts the request for Cross-Origin Resource Sharing.
    # @return boolean
    def accept_cors_request
      headers["Access-Control-Allow-Origin"] = request.env["HTTP_ORIGIN"]
      headers["Access-Control-Allow-Methods"] = "POST, GET, OPTIONS"
      headers["Access-Control-Allow-Headers"] = "Content-Type, Origin, Accept"

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

    def json_response_errors(item)
      full_messages = item.errors.full_messages
      details = item.errors.details
      item.errors.keys.map.with_index do |key, i|
        {
          field: key,
          details: details[key],
          message: full_messages[i]
        }
      end
    end
end
