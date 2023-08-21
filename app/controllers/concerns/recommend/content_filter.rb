module Recommend::ContentFilter
  extend ActiveSupport::Concern

  private

  def set_items
    cur_item = @cur_part || @cur_node
    display_list = []
    @items = []

    return @items if @contents.blank? || cur_item.blank?

    @contents.each do |content|
      content.try(:cur_site=, @cur_site) if content.site_id == @cur_site.id
      next if display_list.index(content.path)

      item = content.content
      next unless item.try(:public?)
      case cur_item.display_target
      when 'page_only'
        model = Cms::Model::Page
      when 'node_only'
        model = Cms::Model::Node
      else
        model = Cms::Content
      end
      next unless item.is_a?(model)

      display_list << content.path
      @items << item
      break if display_list.size >= cur_item.limit
    end

    @items
  end
end
