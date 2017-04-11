class SS::Migration20170411153100
  def change
    ids = Cms::Page.pluck(:id)
    ids.each do |id|
      item = Cms::Page.find(id) rescue nil
      next unless item
      next unless item.respond_to?(:contains_urls)

      item = item.becomes_with_route
      item.set_contains_urls if item.respond_to?(:set_contains_urls)
      item.set_contains_parts_urls if item.respond_to?(:set_contains_parts_urls)
      begin
        item.set(contains_urls: item.contains_urls)
      rescue => e
        Rails.logger.fatal("ss_file save failed #{id}: #{e.backtrace.join("\n  ")}")
      end
    end
  end
end
