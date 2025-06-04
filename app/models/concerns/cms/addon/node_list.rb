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
      field :origin_of_page, type: String, default: "parent1"
      field :origin_of_node, type: String, default: "parent1"
      permit_params node_routes: []
      permit_params :list_origin, :origin_of_page, :origin_of_node
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

    def select_list_origin(page, node)
      if list_origin_deployment?
        return parent
      end

      if page
        select_origin_of_page(page)
      elsif node
        select_origin_of_node(node)
      else
        nil
      end
    end

    def select_origin_of_page(page)
      case origin_of_page
      when "parent2"
        (page.parent ? page.parent.parent : false)
      else #parent1
        page.parent
      end
    end

    def select_origin_of_node(node)
      case origin_of_node
      when "parent2"
        (node.parent ? node.parent.parent : false)
      when "self_node"
        node
      else #parent1
        node.parent
      end
    end

    def list_origin_options
      %w(deployment content).map do |v|
        [ I18n.t("cms.options.list_origin.#{v}"), v ]
      end
    end

    def origin_of_page_options
      %w(parent1 parent2).map do |v|
        [ I18n.t("cms.options.origin_of_page.#{v}"), v ]
      end
    end

    def origin_of_node_options
      %w(parent1 parent2 self_node).map do |v|
        [ I18n.t("cms.options.origin_of_node.#{v}"), v ]
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
