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

      def render_loop_html(value, html: nil)
        (html || loop_html).gsub(/\#\{(.*?)\}/) do |m|
          str = template_variable_get(value, $1) rescue false
          str == false ? m : str
        end
      end

      def template_variable_get(value, name)
        if name == "name"
          value['name']
        elsif name == "url"
          self.try(:url) # TODO: Fix me
        elsif name == "summary"
          value['notes']
        elsif name == "class"
          value['name']
        elsif name == "new"
          in_new_days?(Time.zone.parse(value['metadata_modified']).to_date) ? "new" : nil
        elsif name == "created_date"
          I18n.l Time.zone.parse(value['metadata_created']).to_date
        elsif name =~ /\Acreated_date\.(\w+)\z/
          I18n.l Time.zone.parse(value['metadata_created']).to_date, format: $1.to_sym
        elsif name == "updated_date"
          I18n.l Time.zone.parse(value['metadata_modified']).to_date
        elsif name =~ /\Aupdated_date\.(\w+)\z/
          I18n.l Time.zone.parse(value['metadata_modified']).to_date, format: $1.to_sym
        elsif name == "created_time"
          I18n.l Time.zone.parse(value['metadata_created'])
        elsif name =~ /\Acreated_time\.(\w+)\z/
          I18n.l Time.zone.parse(value['metadata_created']), format: $1.to_sym
        elsif name == "updated_time"
          I18n.l Time.zone.parse(value['metadata_modified'])
        elsif name =~ /\Aupdated_time\.(\w+)\z/
          I18n.l Time.zone.parse(value['metadata_modified']), format: $1.to_sym
        elsif name == "group"
          group = value['groups'].first
          group ? group['display_name'] : ""
        elsif name == "groups"
          value['groups'].map { |g| g['display_name'] }.join(", ")
        else
          false
        end
      end
  end
end
