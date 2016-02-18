module Ckan::Addon
  module Status
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :ckan_url, type: String
      field :ckan_basicauth_state, type: String
      field :ckan_basicauth_username, type: String
      field :ckan_basicauth_password, type: String
      field :ckan_status, type: String
      field :ckan_value_url, type: String
      field :ckan_value_cache, type: Integer
      attr_accessor :in_ckan_basicauth_password
      permit_params :ckan_url, :ckan_basicauth_state, :ckan_basicauth_username, :in_ckan_basicauth_password
      permit_params :ckan_status, :ckan_value_url

      before_validation :set_ckan_basicauth_password, if: ->{ in_ckan_basicauth_password.present? }
      validates :ckan_url, format: /\Ahttps?:\/\//
      validates :ckan_basicauth_state, inclusion: { in: %w(enabled disabled) }
      validates :ckan_status, inclusion: { in: %w(dataset tag group related_item organization) }
    end

    private
      def set_ckan_basicauth_password
        self.ckan_basicauth_password = SS::Crypt.encrypt(in_ckan_basicauth_password)
      end

    public
      def ckan_status_options
        %w(dataset tag group related_item organization).map { |m| [ I18n.t("ckan.options.ckan_status.#{m}"), m ] }.to_a
      end

      def ckan_basicauth_state_options
        %w(enabled disabled).map { |m| [ I18n.t("ckan.options.ckan_basicauth_state.#{m}"), m ] }.to_a
      end

      def ckan_basicauth_enabled?
        ckan_basicauth_state == 'enabled'
      end

      def value
        uri = URI.parse ckan_url + '/api/3/action/' + action_name
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        req = Net::HTTP::Get.new(uri.path)
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
          ckan_value_cache_restore
        else
          h = JSON.parse(res.body)
          if h['success']
            count = h['result'].count
            ckan_value_cache_store(count)
            count
          else
            # Failure
            ckan_value_cache_restore
          end
        end
      end

      def action_name
        {
          'dataset' => 'package_list',
          'tag' => 'tag_list',
          'group' => 'group_list',
          'related_item' => 'related_list',
          'organization' => 'organization_list'
        }[ckan_status]
      end

      def ckan_value_cache_restore
        self.ckan_value_cache || 'NaN'
      end

      def ckan_value_cache_store(new_value)
        self.update ckan_value_cache: new_value
      end
  end
end
