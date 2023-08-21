module Cms::Addon
  module NodeList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      self.use_new_days = false

      cattr_accessor(:use_node_routes, instance_accessor: false, default: false)
      cattr_accessor(:use_list_origin, instance_accessor: false, default: false)

      field :node_routes, type: SS::Extensions::Words
      field :list_origin, type: String
      permit_params node_routes: []
      permit_params :list_origin
      validates :list_origin, inclusion: { in: %w(deployment content), allow_blank: true }
    end

    def sort_options
      %w(name filename created updated_desc order order_desc).map do |k|
        [
          I18n.t("cms.sort_options.#{k}.title"),
          k.sub("_desc", " -1"),
          "data-description" => I18n.t("cms.sort_options.#{k}.description", default: nil)
        ]
      end
    end

    def sort_hash
      return { filename: 1 } if sort.blank?
      { sort.sub(/ .*/, "") => (/-1$/.match?(sort) ? -1 : 1) }
    end

    def list_origin_options
      %w(deployment content).map do |v|
        [ I18n.t("cms.options.list_origin.#{v}"), v ]
      end
    end

    def list_origin_deployment?
      !list_origin_content?
    end

    def list_origin_content?
      list_origin == "content"
    end
  end
end
