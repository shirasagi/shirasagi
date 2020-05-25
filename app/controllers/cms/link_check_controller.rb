require "timeout"
require "open-uri"

class Cms::LinkCheckController < ApplicationController
  include SS::AuthFilter

  protect_from_forgery except: :check
  skip_before_action :verify_authenticity_token, raise: false unless SS.config.env.csrf_protect
  before_action :accept_cors_request
  before_action :set_user

  private

  def set_user
    @cur_user = get_user_by_session
  end

  public

  def check
    results = {}
    url = params[:url]
    root_url = params[:root_url]
    checker = Cms::LinkChecker.new(cur_user: @cur_user, root_url: root_url)

    raise "400" if url.blank?
    url = url.values if url.is_a?(Hash)
    url.each do |link|
      next if results[link]
      results[link] = checker.check_url(link)
    end

    respond_to do |format|
      format.json { render json: results.to_json }
    end
  end
end
