class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  #before_action -> { FileUtils.touch "#{Rails.root}/Gemfile" } if Rails.env.to_s == "development"

  public
    def t(key, opts = {})
      opts[:scope] = [:ss] if key !~ /\./ && !opts[:scope]
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
end
