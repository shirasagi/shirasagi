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

      template_variable_handler :id, :template_variable_common
      template_variable_handler :revision_id, :template_variable_common
      template_variable_handler :name, :template_variable_common
      template_variable_handler :title, :template_variable_common
      template_variable_handler :license_id, :template_variable_common
      template_variable_handler :license_title, :template_variable_common
      template_variable_handler :license_url, :template_variable_common
      template_variable_handler :author, :template_variable_common
      template_variable_handler :author_email, :template_variable_common
      template_variable_handler :maintainer, :template_variable_common
      template_variable_handler :maintainer_email, :template_variable_common
      template_variable_handler :num_tags, :template_variable_common
      template_variable_handler :num_resources, :template_variable_common
      template_variable_handler :private, :template_variable_common
      template_variable_handler :state, :template_variable_common
      template_variable_handler :version, :template_variable_common
      template_variable_handler :type, :template_variable_common
      template_variable_handler :url, :template_variable_url
      template_variable_handler :summary, :template_variable_summary
      template_variable_handler :class, :template_variable_class
      template_variable_handler :new, :template_variable_new
      template_variable_handler :created_date, :template_variable_created_date
      template_variable_handler :'created_date.iso', :template_variable_created_date
      template_variable_handler :'created_date.long', :template_variable_created_date
      template_variable_handler :updated_date, :template_variable_updated_date
      template_variable_handler :'updated_date.iso', :template_variable_updated_date
      template_variable_handler :'updated_date.long', :template_variable_updated_date
      template_variable_handler :created_time, :template_variable_created_time
      template_variable_handler :'created_time.iso', :template_variable_created_time
      template_variable_handler :'created_time.long', :template_variable_created_time
      template_variable_handler :updated_time, :template_variable_updated_time
      template_variable_handler :'updated_time.iso', :template_variable_updated_time
      template_variable_handler :'updated_time.long', :template_variable_updated_time
      template_variable_handler :group, :template_variable_group
      template_variable_handler :groups, :template_variable_groups
      template_variable_handler :organization, :template_variable_organization
      template_variable_handler :add_or_update, :template_variable_add_or_update
      template_variable_handler :add_or_update_text, :template_variable_add_or_update_text
    end

    module ClassMethods
      public
        def template_variable_handler(name, handler)
          handlers = instance_variable_get(:@_template_variable_handlers)
          handlers ||= []
          handlers << [name.to_sym, handler]
          instance_variable_set(:@_template_variable_handlers, handlers)
        end

        def template_variable_handlers
          instance_variable_get(:@_template_variable_handlers) || []
        end
    end

    private
      def set_ckan_basicauth_password
        self.ckan_basicauth_password = SS::Crypt.encrypt(in_ckan_basicauth_password)
      end

      def find_template_variable_handler(name)
        name = name.to_sym
        handler_def = self.class.template_variable_handlers.find { |handler_name, _| handler_name == name }
        return nil unless handler_def

        handler = handler_def[1]
        if handler.is_a?(Symbol) || handler.is_a?(String)
          handler = method(handler)
        end
        handler
      end

      def template_variable_common(name, value)
        value[name].to_s
      end

      def template_variable_url(name, value)
        "#{ckan_item_url}/#{value['name']}"
      end

      def template_variable_summary(name, value)
        value['notes']
      end

      def template_variable_class(name, value)
        value['name']
      end

      def template_variable_new(name, value)
        in_new_days?(Time.zone.parse(value['metadata_modified']).to_date) ? "new" : nil
      end

      def template_variable_created_date(name, value, format = nil)
        if index = name.index('.')
          format = name[index + 1, name.length]
        end

        if format.present?
          I18n.l Time.zone.parse(value['metadata_created']).to_date, format: format.to_sym
        else
          I18n.l Time.zone.parse(value['metadata_created']).to_date
        end
      end

      def template_variable_updated_date(name, value)
        if index = name.index('.')
          format = name[index + 1, name.length]
        end

        if format.present?
          I18n.l Time.zone.parse(value['metadata_modified']).to_date, format: format.to_sym
        else
          I18n.l Time.zone.parse(value['metadata_modified']).to_date
        end
      end

      def template_variable_created_time(name, value)
        if index = name.index('.')
          format = name[index + 1, name.length]
        end

        if format.present?
          I18n.l Time.zone.parse(value['metadata_created']), format: format.to_sym
        else
          I18n.l Time.zone.parse(value['metadata_created'])
        end
      end

      def template_variable_updated_time(name, value)
        if index = name.index('.')
          format = name[index + 1, name.length]
        end

        if format.present?
          I18n.l Time.zone.parse(value['metadata_modified']), format: format.to_sym
        else
          I18n.l Time.zone.parse(value['metadata_modified'])
        end
      end

      def template_variable_group(name, value)
        group = value['groups'].first
        group ? group['display_name'] : ""
      end

      def template_variable_groups(name, value)
        value['groups'].map { |g| g['display_name'] }.join(", ")
      end

      def template_variable_organization(name, value)
        organization = value['organization']
        organization ? organization['title'] : ""
      end

      def template_variable_add_or_update(name, value)
        modified = Time.zone.parse(value['metadata_modified']) rescue Time.zone.at(0)
        created = Time.zone.parse(value['metadata_created']) rescue Time.zone.at(0)
        diff = modified - created
        if diff < 10.seconds || (modified.to_i == 0 && created.to_i != 0)
          "add"
        elsif in_new_days?(modified.to_date)
          "update"
        end
      end

      def template_variable_add_or_update_text(name, value)
        label = template_variable_add_or_update(name, value)
        if label.present?
          label = I18n.t("ckan.node.page.#{label}")
        end
        label
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

      def render_loop_html(value, html: nil)
        (html || loop_html).gsub(/\#\{(.*?)\}/) do |m|
          str = template_variable_get(value, $1) rescue false
          str == false ? m : str
        end
      end

      def template_variable_get(value, name)
        handler = find_template_variable_handler(name)
        return unless handler

        handler.call(name, value)
      end
  end
end
