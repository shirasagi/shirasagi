module Ckan::Addon
  module Server
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :ckan_url, type: String
      field :ckan_basicauth_state, type: String
      field :ckan_basicauth_username, type: String
      field :ckan_basicauth_password, type: String
      field :ckan_max_docs, type: Integer
      field :ckan_item_url, type: String
      field :ckan_values_cache, type: Binary
      attr_accessor :in_ckan_basicauth_password
      permit_params :ckan_url, :ckan_max_docs
      permit_params :ckan_basicauth_state, :ckan_basicauth_username, :in_ckan_basicauth_password, :ckan_item_url

      before_validation :set_ckan_basicauth_password, if: ->{ in_ckan_basicauth_password.present? }
      validates :ckan_url, format: /\Ahttps?:\/\//
      validates :ckan_max_docs, numericality: { greater_than_or_equal_to: 0 }
      validates :ckan_item_url, format: /\Ahttps?:\/\//
    end

    private
      def set_ckan_basicauth_password
        self.ckan_basicauth_password = SS::Crypt.encrypt(in_ckan_basicauth_password)
      end

    public
      def ckan_basicauth_state_options
        %w(enabled disabled).map { |m| [ I18n.t("ckan.options.ckan_basicauth_state.#{m}"), m ] }.to_a
      end

      def ckan_basicauth_enabled?
        ckan_basicauth_state == 'enabled'
      end

      def values
        uri = URI.parse "#{ckan_url}/api/3/action/package_search?rows=#{ckan_max_docs}&sort=metadata_modified+desc"
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        req = Net::HTTP::Get.new(uri.path + '?' + uri.query)
        if ckan_basicauth_enabled?
          req.basic_auth(ckan_basicauth_username, SS::Crypt.decrypt(ckan_basicauth_password))
        end
        res = http.request(req)
        if res.code != '200'
          # HTTP Error
          ckan_values_cache_restore
        else
          h = JSON.parse(res.body)
          if h['success']
            results = h['result']['results']
            ckan_values_cache_store results
            results
          else
            # Failure
            ckan_values_cache_restore
          end
        end
      end

      def ckan_values_cache_restore
        if self.ckan_values_cache.present?
          Marshal.load(ckan_values_cache)
        else
          []
        end
      end

      def ckan_values_cache_store new_values
        self.update ckan_values_cache: Marshal.dump(new_values)
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
          "#{ckan_item_url}/#{value['name']}"
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
