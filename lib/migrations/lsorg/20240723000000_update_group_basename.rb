class SS::Migration20240723000000
  include SS::Migration::Base

  depends_on "20240424000000"

  def change
    ids = SS::Group.unscoped.pluck(:id)
    ids.each do |id|
      item = SS::Group.unscoped.find(id) rescue nil
      next if item.basename.present?

      item.send(:set_basename)
      item.set(basename: item.basename)
    end
  end
end
