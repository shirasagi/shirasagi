require "timeout"
require "open-uri"

class Cms::LinkCheckController < ApplicationController
  protect_from_forgery except: :check
  skip_before_action :verify_authenticity_token unless SS.config.env.csrf_protect
  before_action :accept_cors_request

  def check
    result = {}
    url = params[:url]

    raise "400" if url.blank?
    url = url.values if url.is_a?(Hash)
    url.each do |link|
      next if result[link]
      result[link] = check_url(::URI.escape(link))
    end

    respond_to do |format|
      format.json { render json: result.to_json }
    end
  end

  private

  def check_url(url)
    proxy = ( url =~ /^https/ ) ? ENV['HTTPS_PROXY'] : ENV['HTTP_PROXY']
    progress_data_size = nil
    opts = {
      proxy: proxy,
      progress_proc: ->(size) do
          progress_data_size = size
          raise "200"
      end
    }

    begin
      timeout(2) do
        open(url, opts) { |f| return f.status[0].to_i }
      end
    rescue TimeoutError
      return 0
    rescue => e
      return 200 if progress_data_size
    end
    return 0
  end
end
