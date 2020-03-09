module Opendata::Resource::HistoryModel
  extend ActiveSupport::Concern
  extend SS::Translation
  include Cms::Reference::Site
  include Cms::SitePermission

  included do
    cattr_accessor :issued_at_field, instance_accessor: false

    set_permission_name "opendata_histories", :read

    field :dataset_id, type: Integer
    field :dataset_name, type: String

    field :dataset_areas, type: Array, default: []
    field :dataset_categories, type: Array, default: []
    field :dataset_estat_categories, type: Array, default: []

    field :resource_id, type: Integer
    field :resource_name, type: String
    field :resource_filename, type: String
    field :resource_format, type: String
    field :resource_source_url, type: String

    field :full_url, type: String
    field :remote_addr, type: String
    field :user_agent, type: String
  end

  module ClassMethods
    def create_history(options)
      options = options.dup
      site = options.delete(:site)
      dataset = options.delete(:dataset)
      resource = options.delete(:resource)
      remote_addr = options.delete(:remote_addr)
      user_agent = options.delete(:user_agent)

      attrs = {
        cur_site: site,
        dataset_id: dataset.id,
        dataset_name: dataset.name,
        dataset_areas: dataset.areas.and_public.order_by(order: 1).pluck(:name),
        dataset_categories: dataset.categories.and_public.order_by(order: 1).pluck(:name),
        dataset_estat_categories: dataset.estat_categories.and_public.order_by(order: 1).pluck(:name),
        resource_id: resource.id,
        resource_name: resource.name,
        resource_filename: resource.filename,
        resource_format: resource.format,
        resource_source_url: resource.source_url,
        full_url: dataset.full_url,
        remote_addr: remote_addr,
        user_agent: user_agent
      }
      options.each do |key, value|
        attrs[key] = value
      end

      create(attrs)
    end

    def search(params)
      all.search_ymd(params).search_keyword(params)
    end

    def search_ymd(params)
      return all if params.blank? || params[:ymd].blank?

      ymd = params[:ymd]
      ymd = Time.zone.parse(ymd) if ymd.is_a?(String)
      ymd = ymd.in_time_zone
      ymd = ymd.beginning_of_day

      all.gte(issued_at_field => ymd).lt(issued_at_field => ymd + 1.day)
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?

      all.keyword_in params[:keyword], :dataset_name, :resource_name
    end
  end
end
