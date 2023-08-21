class SS::Migration20190610000000
  include SS::Migration::Base

  depends_on "20190513130500"

  def change
    ids = Gws::Monitor::Topic.all.pluck(:id)
    ids.each do |id|
      item = Gws::Monitor::Topic.find(id) rescue nil
      next unless item
      next unless ::File.exist?(item.zip_path)
      ::File.unlink(item.zip_path)
    end
  end
end
