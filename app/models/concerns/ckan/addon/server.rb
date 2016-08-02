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
      field :ckan_json_cache, type: String
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

      def find_template_variable_handler(name)
        name = name.to_sym
        handler_def = self.class.template_variable_handlers.find { |handler_name, _| handler_name == name }
        return nil unless handler_def

        case handler = handler_def[1]
        when ::Symbol, ::String
          method(handler)
        when ::Proc
          myself = self
          lambda { |name, value| myself.instance_exec(name, value, &handler) }
        else
          handler
        end
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
        res = begin
          res = http.request(req)
          if res.code != '200'
            res = nil
          end
          res
        rescue
          nil
        end

        if res.blank?
          # HTTP Error
          ckan_json_cache_restore
        else
          h = JSON.parse(res.body)
          if h['success']
            ckan_json_cache_store res.body
            h['result']['results']
          else
            # Failure
            ckan_json_cache_restore
          end
        end
      end

      def ckan_json_cache_restore
        if self.ckan_json_cache.present?
          JSON.parse(self.ckan_json_cache)['result']['results']
        else
          []
        end
      end

      def ckan_json_cache_store new_json
        self.update ckan_json_cache: new_json
      end
  end
end
