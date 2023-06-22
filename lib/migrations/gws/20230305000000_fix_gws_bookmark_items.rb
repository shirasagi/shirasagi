class SS::Migration20230305000000
  include SS::Migration::Base

  def change
    model = Gws::Bookmark::Item
    all_ids = model.pluck(:id)
    all_ids.each_slice(20) do |ids|
      model.in(id: ids).each do |item|
        user = item.user
        site = item.site

        next if item.folder
        next if user.nil?
        next if site.nil?

        item.folder = user.bookmark_root_folder(site)
        item.update!
      end
    end
  end
end
