require "timeout"
require "open-uri"

class Cms::LinkCheckController < ApplicationController
  protect_from_forgery except: :check
  before_action :accept_cors_request

  public
    def check
      result = {}
      raise "400" if params[:url].blank?

      params[:url].each_value do |link|
        next if result[link]
        result[link] = check_url(link)
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
