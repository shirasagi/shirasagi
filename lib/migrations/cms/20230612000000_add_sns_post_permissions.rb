class SS::Migration20230612000000
  include SS::Migration::Base

  depends_on "20230410000000"

  def change
    targets = %w(
      edit_other_article_pages
      edit_private_article_pages
      edit_other_cms_pages
      edit_private_cms_pages
    ).compact

    permission = "use_cms_page_twitter_posts"
    sites = Cms::Site.all.to_a.select { |site| site.twitter_poster_enabled? }
    sites.each do |site|
      Cms::Role.site(site).in(:permissions.in => targets).each do |item|
        next if item.permissions.include?(permission)
        item.permissions += [permission]
        item.update
        puts "Updated cms_role: #{item.id} #{item.name}"
      end
    end

    permission = "use_cms_page_line_posts"
    sites = Cms::Site.all.to_a.select { |site| site.line_poster_enabled? }
    sites.each do |site|
      Cms::Role.site(site).in(:permissions.in => targets).each do |item|
        next if item.permissions.include?(permission)
        item.permissions += [permission]
        item.update
        puts "Updated cms_role: #{item.id} #{item.name}"
      end
    end
  end
end
