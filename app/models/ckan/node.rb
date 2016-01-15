module Ckan::Node
  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Ckan::Addon::Server
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "ckan/page") }

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
