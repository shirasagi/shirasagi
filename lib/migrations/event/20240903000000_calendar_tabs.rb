class SS::Migration20240903000000
  include SS::Migration::Base

  depends_on "20240729000000"

  def change
    ids = Event::Node::Page.pluck(:id)
    ids.each do |id|
      item = Event::Node::Page.find(id) rescue nil
      next if item.nil?
      next if item.event_display_tabs.present?

      case item.event_display
      when "list"
        item.event_display = "list"
        item.event_display_tabs = %w(list table)
      when "table"
        item.event_display = "table"
        item.event_display_tabs = %w(list table)
      when "table_only"
        item.event_display = "table"
        item.event_display_tabs = %w(table)
      else # "list_only"
        item.event_display = "list"
        item.event_display_tabs = %w(list)
      end
      item.without_record_timestamps { item.update }
    end
  end
end
