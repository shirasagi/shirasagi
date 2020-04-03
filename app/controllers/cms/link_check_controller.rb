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

  def check_url(url)
    @head_request_timeout = SS.config.cms.check_links["head_request_timeout"] rescue 5
    progress_data_size = nil

    url = normalize_url(url)
    proxy = ( url =~ /^https/ ) ? ENV['HTTPS_PROXY'] : ENV['HTTP_PROXY']
    http_basic_authentication = SS::MessageEncryptor.http_basic_authentication
    opts = {
      proxy: proxy,
      http_basic_authentication: http_basic_authentication,
      progress_proc: ->(size) do
        progress_data_size = size
        raise "200"
      end
    }

    Timeout.timeout(@head_request_timeout) do
      open(url, opts) { |_f| }
    end

    200
  rescue URI::InvalidURIError
    0
  rescue Timeout::Error
    0
  rescue => _e
    progress_data_size ? 200 : 0
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

  public

  def check
    result = {}
    url = params[:url]
    @root_url = params[:root_url].presence
    @fs_url = ::File.join(@root_url, "/fs/") if @root_url

    raise "400" if url.blank?
    url = url.values if url.is_a?(Hash)
    url.each do |link|
      next if result[link]
      result[link] = check_url(link)
    end

    respond_to do |format|
      format.json { render json: result.to_json }
    end
  end
end
