module Recommend::Addon
  module ContentList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      cattr_accessor(:use_display_target, instance_accessor: false) { true }
      field :exclude_paths, type: SS::Extensions::Lines
      field :display_target, type: String
      permit_params :exclude_paths, :display_target
    end

    def display_target_options
      I18n.t("recommend.options.display_target").map { |k, v| [v, k] }
    end

    def condition_hash(options = {})
      cond = []
      if conditions.present?
        paths = conditions.map { |path| path.start_with?("/") ? /\A#{path}/ : /\A\/#{path}/ }
        cond << { path: { "$in" => paths } }
      end
      if exclude_paths.present?
        paths = exclude_paths.map { |path| path.start_with?("/") ? /\A#{path}/ : /\A\/#{path}/ }
        cond << { path: { "$nin" => paths } }
      end
      cond.present? ? { "$and" => cond } : {}
    end

    def limit
      value = self[:limit].to_i
      (value < 1 || 50 < value) ? 5 : value
    end
  end
end
