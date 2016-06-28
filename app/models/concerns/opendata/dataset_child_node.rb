module Opendata::DatasetChildNode
  extend ActiveSupport::Concern

  included do
    attr_accessor :cur_subcategory
  end

  public
    def parent_dataset_node
      @parent_dataset_node = begin
        node = self
        while node
          node = node.becomes_with_route
          if node.is_a?(Opendata::Node::Dataset)
            break
          end
          node = node.parent
        end
        node ||= Opendata::Node::Dataset.site(site).public.first
        node
      end
    end

    def related_category
      category_path = url.sub(parent_dataset_node.url, '')
      category_path = category_path[0..-2] if category_path.end_with?('/')
      category_path = "#{category_path}/#{@cur_subcategory}" if @cur_subcategory

      node = Cms::Node.site(@cur_site || self.site).public.where(filename: category_path).first
      return node.becomes_with_route if node

      (parent_dataset_node.st_categories || parent_dataset_node.default_st_categories || []).each do |cate|
        node = Cms::Node.site(@cur_site || self.site).public.where(filename: "#{cate.filename}/#{category_path}").first
        return node.becomes_with_route if node
      end

      nil
    end
end
