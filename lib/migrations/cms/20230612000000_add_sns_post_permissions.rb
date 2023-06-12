class SS::Migration20230612000000
  include SS::Migration::Base

  depends_on "20230410000000"

  def change
    targets = %w(
      read_other_article_pages
      read_private_article_pages
      read_other_cms_pages
      read_private_cms_pages
    ).compact

    sites = Cms::Site.all.to_a.select { |site| site.twitter_poster_enabled? || site.line_poster_enabled? }
    sites.each do |site|
      Cms::Role.site(site).in(:permissions.in => targets).each do |item|
        next if item.permissions.include?("use_cms_page_sns_posts")
        item.permissions += %w(use_cms_page_sns_posts)
        item.update
        puts "Updated cms_role: #{item.id} #{item.name}"
      end
    end
  end
end
