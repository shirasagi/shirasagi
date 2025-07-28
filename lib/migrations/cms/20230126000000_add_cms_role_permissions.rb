class SS::Migration20230126000000
  include SS::Migration::Base

  depends_on "20220928000000"

  def change
    targets = %w(
      release_other_article_pages
      release_private_article_pages

      release_other_cms_pages
      release_private_cms_pages

      release_other_event_pages
      release_private_event_pages

      release_other_faq_pages
      release_private_faq_pages

      release_other_member_blogs
      release_private_member_blogs
      release_other_member_photos
      release_private_member_photos

      release_other_opendata_datasets
      release_private_opendata_datasets
      release_member_opendata_datasets

      release_other_opendata_apps
      release_private_opendata_apps
      release_member_opendata_apps

      release_other_opendata_ideas
      release_private_opendata_ideas
      release_member_opendata_ideas

      release_other_sitemap_pages
      release_private_sitemap_pages
    ).compact

    Cms::Role.where(:permissions.in => targets).each do |item|
      permissions = item.permissions
      targets.each do |src|
        dst = src.sub(/\Arelease_/, 'close_')
        next unless permissions.include?(src)
        next if permissions.include?(dst)
        permissions << dst
      end
      next if permissions == item.permissions

      item.set(permissions: permissions)
      puts "Updated cms_role: #{item.id} #{item.name}"
    end
  end
end
