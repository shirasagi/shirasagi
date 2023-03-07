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

        if user.try(:lang).present?
          I18n.locale = user.lang.to_sym
        else
          I18n.locale = I18n.default_locale
        end
        item.folder = user.bookmark_root_folder(site)
        item.update!
        p item.name
      end
    end
  end
end
