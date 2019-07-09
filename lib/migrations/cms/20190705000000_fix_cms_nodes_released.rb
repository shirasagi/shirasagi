class SS::Migration20190705000000
  def change
    ids = Cms::Node.all.pluck(:id)
    ids.each do |id|
      node = Cms::Node.find(id) rescue nil
      next unless node

      begin
        node = node.becomes_with_route
        node.set(released: node.updated) if node.released.nil?
        node.set(first_released: node.updated) if node.first_released.nil?
      rescue => e
        puts "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
      end
    end
  end
end
