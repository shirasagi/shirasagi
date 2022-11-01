module Cms::Addon
  module NodeList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      self.use_new_days = false

      cattr_accessor(:use_node_routes, instance_accessor: false, default: false)
      field :node_routes, type: SS::Extensions::Words
      permit_params node_routes: []
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
  end
end
