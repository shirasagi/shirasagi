require 'csv'

class Cms::NodeExporter

  include ActiveModel::Model
  attr_accessor :site, :criteria

  def enum_csv(options = {})
    drawer = SS::Csv.draw(:export, context: self) do |drawer|

      drawer_columns = I18n.t('cms.node_columns').invert
      csv_headers = drawer_columns.keys
      
      csv_headers.each do |header|
        drawer.column drawer_columns["#{header}"] do
          drawer.head { header }
        
          case header
          when I18n.t('cms.node_columns.layout_filename')
            drawer.body { |item| format_layout(item) }
        
          when I18n.t('cms.node_columns.page_layout_filename')
            drawer.body { |item| format_page_layout(item) }
        
          when I18n.t('cms.node_columns.category_ids')
            drawer.body { |item| format_category(item) }
        
          when I18n.t('cms.node_columns.group_ids')
            drawer.body { |item| format_group(item) }
        
          when I18n.t('cms.node_columns.shortcut')
            drawer.body { |item| item.label(:shortcut) if item.respond_to?(:shortcut) && item.shortcut.present? }
        
          when I18n.t('cms.node_columns.view_route')
            drawer.body { |item| item.label(:view_route) if item.respond_to?(:view_route) && item.view_route.present? }
        
          when I18n.t('cms.node_columns.keywords')
            drawer.body { |item| item.keywords.join("\n") if item.respond_to?(:keywords) && item.keywords.present? }
        
          when I18n.t('cms.node_columns.conditions')
            drawer.body { |item| item.conditions.join("\n") if item.respond_to?(:conditions) && item.conditions.present? }
        
          when I18n.t('cms.node_columns.sort')
            drawer.body { |item| item.label(:sort) if item.respond_to?(:sort) && item.sort.present? }
        
          when I18n.t('cms.node_columns.loop_format')
            drawer.body { |item| item.label(:loop_format) if item.respond_to?(:loop_format) && item.loop_format.present? }
        
          when I18n.t('cms.node_columns.no_items_display_state')
            drawer.body { |item| item.label(:no_items_display_state) if item.respond_to?(:no_items_display_state) && item.no_items_display_state.present? }
        
          when I18n.t('cms.node_columns.released_type')
            drawer.body { |item| item.label(:released_type) if item.respond_to?(:released_type) && item.released_type.present? }
        
          when I18n.t('cms.node_columns.released')
            drawer.body { |item| I18n.l(item.released, format: :picker) if item.respond_to?(:released) && item.released.present? }
        
          when I18n.t('cms.node_columns.state')
            drawer.body { |item| item.label(:state) if item.respond_to?(:state) && item.state.present? }
          end
        end
        
      end
    end
    drawer.enum(criteria, options)
  end

  private
  
  def format_layout(item)
    return '' if !item.respond_to?(:layout)

    return '' if item.layout.blank?
    
    "#{item.layout.name} (#{item.layout.filename})"
  end

  def format_page_layout(item)
    return '' if !item.respond_to?(:page_layout)

    return '' if  item.page_layout.blank?

    "#{item.page_layout.name} (#{item.page_layout.filename})"
  end
  
  def format_category(item)
    item.st_categories.map { |cate| "#{cate.name} (#{cate.filename})" }.join("\n") if (item.respond_to?(:st_categories) && item.st_categories.present?)
  end

  def format_group(item)
    item.groups.map(&:name).join("\n") if ( item.respond_to?(:groups) && item.groups.present? )
  end
end
