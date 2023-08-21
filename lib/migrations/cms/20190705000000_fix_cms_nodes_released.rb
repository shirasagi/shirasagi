class SS::Migration20190705000000
  include SS::Migration::Base

  depends_on "20190619000000"

  def change
    ids = Cms::Node.and_public.where(released: nil).pluck(:id)
    ids.each do |id|
      node = Cms::Node.find(id) rescue nil
      next unless node

      begin
        node.set(released: node.updated) if node.released.nil?
      rescue => e
        puts "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
      end
    end

    ids = Cms::Node.and_public.where(first_released: nil).pluck(:id)
    ids.each do |id|
      node = Cms::Node.find(id) rescue nil
      next unless node

      begin
        node.set(first_released: node.updated) if node.first_released.nil?
      rescue => e
        puts "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
      end
    end
  end
end
