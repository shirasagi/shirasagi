module Gws::SearchForm
  class Target
    include SS::Document
    include Gws::Reference::Site
    include Gws::Reference::User
    include Gws::SitePermission

    set_permission_name "gws_groups", :edit

    seqid :id
    field :name, type: String
    field :place_holder, type: String
    field :state, type: String, default: "enabled"
    field :order, type: Integer, default: 0
    field :search_service, type: String
    field :search_url, type: String
    field :search_keyword_name, type: String
    field :search_other_query, type: String

    permit_params :name, :place_holder, :order, :search_service, :search_url,
      :search_keyword_name, :search_other_query, :state

    validates :name, presence: true, length: { maximum: 40 }
    validates :place_holder, presence: true, length: { maximum: 40 }
    validates :search_service, presence: true
    validates :search_url, presence: true, if: ->{ search_external? }
    validates :search_keyword_name, presence: true, if: ->{ search_external? }

    default_scope ->{ order_by(order: 1) }

    def state_options
      %w(enabled disabled).map do |v|
        [ I18n.t("ss.options.state.#{v}"), v ]
      end
    end

    def search_service_options
      I18n.t("gws/search_form.options.search_service").map { |k, v| [v, k] }
    end

    def search_external?
      search_service == "external"
    end

    def url
      return search_url if search_external?
      url_helper = Rails.application.routes.url_helpers
      url_helper.gws_elasticsearch_search_search_path(site: site_id, type: "all")
    end

    def url_without_keyword
      ret = "#{url}?#{keyword_name}=KEYWORD"
      ret += "&#{search_other_query}" if search_other_query.present?
      ret
    end

    def keyword_name
      search_external? ? search_keyword_name : "s[keyword]"
    end

    def other_query
      return {} if search_other_query.blank?
      Rack::Utils.parse_nested_query(search_other_query) rescue {}
    end

    class << self
      def search(params)
        criteria = all
        return criteria if params.blank?

        if params[:name].present?
          criteria = criteria.search_text params[:name]
        end
        if params[:keyword].present?
          criteria = criteria.keyword_in params[:keyword], :name
        end
        criteria
      end

      def and_enabled
        self.where(state: "enabled")
      end

      def and_external
        self.where(search_service: "external")
      end
    end
  end
end
