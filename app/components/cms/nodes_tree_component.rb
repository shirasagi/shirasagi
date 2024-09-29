# app/components/cms/nodes_tree_component.rb
require 'net/http'
require 'json'

module Cms
  class NodesTreeComponent < ViewComponent::Base
    def initialize(api_url:, request:)
      @api_url = api_url
      @request = request
      @folders = fetch_folders
    end

    private

    def fetch_folders
      full_url = full_api_url(@api_url)
      Rails.logger.info "Fetching folders from #{full_url}"

      uri = URI(full_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      request = Net::HTTP::Get.new(uri)

      request['Cookie'] = @request.headers['Cookie']

      response = http.request(request)
      if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)
      else
        Rails.logger.error "Error fetching folders: #{response.body}"
        []
      end
    rescue StandardError => e
      Rails.logger.error "Error fetching folders: #{e.message}"
      []
    end

    def full_api_url(relative_url)
      if relative_url.start_with?('http')
        relative_url
      else
        "#{@request.base_url}#{relative_url}"
      end
    end
  end
end
