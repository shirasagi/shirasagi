module Category::CategoryHelper
  extend ActiveSupport::Concern

  class Internals
    def initialize(caller, item, cate_options)
      @caller = caller
      @item = item
      @unreadable_categories = []

      cate_options ||= {}
      @readable = cate_options[:readable].presence
      @root_and_descendants = cate_options[:root_and_descendants]
      @item_name = cate_options[:item_name] || "category_ids"
    end

    def child?(cate0, cate1)
      cate1.filename.start_with?("#{cate0.filename}/") && cate0.depth + 1 == cate1.depth
    end

    def brother?(cate0, cate1)
      return false if cate0.depth != cate1.depth

      last_slash0 = cate0.filename.rindex("/")
      last_slash1 = cate1.filename.rindex("/")
      return false if last_slash0 != last_slash1
      return true if last_slash0.nil?

      cate0.filename[0..last_slash0] == cate1.filename[0..last_slash1]
    end

    def children(categories, cate0)
      categories.select { |cate| child?(cate0, cate) }
    end

    def render_cate_form0(categories, item)
      children = children(categories, item)

      if @readable && item.respond_to?(:readable?) && !item.readable?(*@readable)
        @unreadable_categories << item
        if children.present?
          children.each { |c| render_cate_form0 categories, c }
        end
      elsif children.present?
        @caller.output_buffer << @caller.content_tag("div", class: "parent") do
          cc = children.map { |c| children(categories, c).size }.max != 0
          @caller.output_buffer << @caller.content_tag("label", class: "parent") do
            @caller.output_buffer << @caller.check_box_tag("item[#{@item_name}][]", item.id, @item.send(@item_name).include?(item.id), {data: {url: item.filename}})
            @caller.output_buffer << " "
            @caller.output_buffer << item.name
          end

          @caller.output_buffer << @caller.content_tag("div", class: ["child", cc ? "grandchild" : nil]) do
            children.each { |c| render_cate_form1 categories, c }
          end
        end
      else
        @caller.output_buffer << @caller.content_tag("div", class: "parent") do
          @caller.output_buffer << @caller.content_tag("label") do
            @caller.output_buffer << @caller.check_box_tag("item[#{@item_name}][]", item.id, @item.send(@item_name).include?(item.id), {data: {url: item.filename}})
            @caller.output_buffer << " "
            @caller.output_buffer << item.name
          end
        end
      end

      categories.delete(item)
    end

    def render_cate_form1(categories, item)
      children = children(categories, item)

      if @readable && item.respond_to?(:readable?) && !item.readable?(*@readable)
        @unreadable_categories << item
        if children.present?
          children.each { |c| render_cate_form1 categories, c }
        end
      elsif children.present?
        cc = children.map { |c| children(categories, c).size }.max != 0
        @caller.output_buffer << @caller.content_tag("label", class: "parent") do
          @caller.output_buffer << @caller.check_box_tag("item[#{@item_name}][]", item.id, @item.send(@item_name).include?(item.id), {data: {url: item.filename}})
          @caller.output_buffer << " "
          @caller.output_buffer << item.name
        end

        @caller.output_buffer << @caller.content_tag("div", class: ["child", cc ? "grandchild" : nil]) do
          children.each { |c| render_cate_form1 categories, c }
        end
      else
        @caller.output_buffer << @caller.content_tag("label") do
          @caller.output_buffer << @caller.check_box_tag("item[#{@item_name}][]", item.id, @item.send(@item_name).include?(item.id), {data: {url: item.filename}})
          @caller.output_buffer << " "
          @caller.output_buffer << item.name
        end
      end

      categories.delete(item)
    end

    def render_unreadable_categories
      @caller.output_buffer << @caller.content_tag("div", class: "unreadable", style: "display:none;") do
        @unreadable_categories.each do |item|
          @caller.output_buffer << @caller.content_tag("label") do
            @caller.output_buffer << @caller.check_box_tag("item[#{@item_name}][]", item.id, @item.send(@item_name).include?(item.id), {data: {url: item.filename}})
            @caller.output_buffer << " "
            @caller.output_buffer << item.name
          end
        end
      end
    end

    def render_cate_form(categories)
      loop do
        cate = categories.shift
        break if cate.blank?

        next if @root_and_descendants && cate.depth > 1

        @caller.output_buffer << render_cate_form0(categories, cate)
      end

      if @unreadable_categories.present?
        render_unreadable_categories
      end
    end
  end

  def render_cate_form(categories, cate_options)
    Internals.new(self, @item, cate_options).render_cate_form(categories)
  end
end
