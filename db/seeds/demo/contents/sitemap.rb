puts "sitemap"
sitemap_urls = File.read("sitemap/urls.txt") rescue nil
save_page route: "sitemap/page", filename: "sitemap/index.html", name: "サイトマップ",
  layout_id: @layouts["general"].id, sitemap_urls: sitemap_urls
