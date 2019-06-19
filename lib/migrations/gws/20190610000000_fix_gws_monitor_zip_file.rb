class SS::Migration20190610000000
  def change
    ids = Gws::Monitor::Topic.all.pluck(:id)
    ids.each do |id|
      item = Gws::Monitor::Topic.find(id) rescue nil
      next unless item
      next unless ::File.exists?(item.zip_path)
      ::File.unlink(item.zip_path)
    end
  end
end
