module Ckan::Addon
  module Status
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :ckan_url, type: String
      field :ckan_status, type: String
      permit_params :ckan_url, :ckan_status
    end

    public
      def ckan_status_options
        %w(dataset tag group related_item).map { |m| [ I18n.t("ckan.options.ckan_status.#{m}"), m ] }.to_a
      end

      def value
        uri = URI.parse ckan_url + '/api/3/action/' + action_name
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        req = Net::HTTP::Get.new(uri.path)
        res = http.request(req)
        if res.code != '200'
          # HTTP Error
          'NaN'
        else
          h = JSON.parse(res.body)
          if h['success']
            h['result'].count
          else
            # Failure
            'NaN'
          end
        end
      end

      def action_name
        {
          'dataset' => 'package_list',
          'tag' => 'tag_list',
          'group' => 'group_list',
          'related_item' => 'related_list'
        }[ckan_status]
      end
  end
end
