module Ckan::Addon
  module Server
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :ckan_url, type: String
      field :ckan_max_docs, type: Integer
      permit_params :ckan_url, :ckan_max_docs

      validates :ckan_url, format: /\Ahttps?:\/\//
      validates :ckan_max_docs, numericality: { greater_than_or_equal_to: 0 }
    end

    public
      def values
        uri = URI.parse "#{ckan_url}/api/3/action/package_search?rows=#{ckan_max_docs}&sort=metadata_modified+desc"
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        req = Net::HTTP::Get.new(uri.path + '?' + uri.query)
        res = http.request(req)
        if res.code != '200'
          # HTTP Error
          []
        else
          h = JSON.parse(res.body)
          if h['success']
            h['result']['results']
          else
            # Failure
            []
          end
        end
      end
  end
end
