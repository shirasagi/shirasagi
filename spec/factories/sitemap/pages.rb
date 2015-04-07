FactoryGirl.define do
  factory :sitemap_page, class: Sitemap::Page, traits: [:cms_page] do
    filename { "dir/#{unique_id}" }
    route "sitemap/page"
  end
end
