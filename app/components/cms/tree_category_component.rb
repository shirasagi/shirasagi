class Cms::TreeCategoryComponent < ApplicationComponent
  include SS::CacheableComponent

  self.cache_key = ->{
    [ cur_site.id, item_name, max_updated, category_key, readable_category_key, root_and_descendants ]
  }

  attr_reader :cur_site, :root_and_descendants, :item_name, :selected

  def initialize(cur_site, categories, opts = {})
    super()
    @cur_site = cur_site
    @categories = categories

    @readable_categories = opts[:readable_categories] || categories
    @root_and_descendants = opts[:root_and_descendants].present?
    @item_name = opts[:item_name].presence || "category_ids"
    @selected = opts[:selected] || []
  end

  def category_ids
    @category_ids ||= @categories.pluck(:id).sort
  end

  def readable_category_ids
    @readable_category_ids ||= @readable_categories.pluck(:id).sort
  end

  def max_updated
    @max_updated ||= Category::Node::Base.site(@cur_site).max(:updated)
  end

  def category_key
    @category_key ||= category_ids.join(",")
  end

  def readable_category_key
    @readable_category_key ||= readable_category_ids.join(",")
  end

  def render_cate_form
    @tree = Cms::NodeTree.build(@categories.tree_sort.to_a)
    @roots = @tree.roots
    @roots = @roots.select { |item| item.depth == 1 } if root_and_descendants

    @unreadable_categories = []
    @roots.each do |item|
      render_cate_form0(item)
    end
    render_unreadable_categories
  end

  def render_cate_form0(item)
    if !readable_category_ids.include?(item.id)
      @unreadable_categories << item
      if item.children.present?
        item.children.each { |c| render_cate_form0 c }
      end
    elsif item.children.present?
      output_buffer << tag.div(class: "parent") do
        cc = (item.descendants.size != item.children.size)

        output_buffer << tag.label(class: "parent") do
          output_buffer << check_box_tag(
            "item[#{item_name}][]", item.id, false, id: nil, data: { url: item.filename, unchecked: item.id })
          output_buffer << " "
          output_buffer << item.name
        end
        output_buffer << "\n"

        output_buffer << tag.div(class: ["child", cc ? "grandchild" : nil]) do
          item.children.each { |c| render_cate_form1 c }
        end
      end
    else
      output_buffer << tag.div(class: "parent") do
        output_buffer << tag.label do
          output_buffer << check_box_tag(
            "item[#{item_name}][]", item.id, false, id: nil, data: { url: item.filename, unchecked: item.id })
          output_buffer << " "
          output_buffer << item.name
        end
        output_buffer << "\n"
      end
    end
  end

  def render_cate_form1(item)
    if !readable_category_ids.include?(item.id)
      @unreadable_categories << item
      if item.children.present?
        item.children.each { |c| render_cate_form1 c }
      end
    elsif item.children.present?
      cc = (item.descendants.size != item.children.size)

      output_buffer << tag.label(class: "parent") do
        output_buffer << check_box_tag(
          "item[#{item_name}][]", item.id, false, id: nil, data: { url: item.filename, unchecked: item.id })
        output_buffer << " "
        output_buffer << item.name
      end
      output_buffer << "\n"

      output_buffer << tag.div(class: ["child", cc ? "grandchild" : nil]) do
        item.children.each { |c| render_cate_form1 c }
      end
    else
      output_buffer << tag.label do
        output_buffer << check_box_tag(
          "item[#{item_name}][]", item.id, false, id: nil, data: { url: item.filename, unchecked: item.id })
        output_buffer << " "
        output_buffer << item.name
      end
      output_buffer << "\n"
    end
  end

  def render_unreadable_categories
    return if @unreadable_categories.blank?

    output_buffer << tag.div(class: "unreadable", style: "display:none;") do
      @unreadable_categories.each do |item|
        output_buffer << tag.label do
          output_buffer << check_box_tag(
            "item[#{item_name}][]", item.id, false, id: nil, data: { url: item.filename, unchecked: item.id })
          output_buffer << " "
          output_buffer << item.name
        end
      end
    end
  end
end
