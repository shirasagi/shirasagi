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

  private
    def remote_addr
      request.env["HTTP_X_REAL_IP"] || request.remote_addr
    end
end
