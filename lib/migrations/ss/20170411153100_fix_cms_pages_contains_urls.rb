class SS::Migration20170411153100
  def change
    ids = Cms::Page.pluck(:id)
    ids.each do |id|
      item = Cms::Page.find(id) rescue nil
      next unless item
      next unless item.respond_to?(:contains_urls)

      item = item.becomes_with_route
      if item.respond_to?(:set_contains_urls, true)
        item.send(:set_contains_urls)
      end
      if item.respond_to?(:set_parts_contains_urls, true)
        item.send(:set_parts_contains_urls)
      end
      item.set(contains_urls: item.contains_urls)
    end
  end
end
