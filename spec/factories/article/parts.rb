FactoryGirl.define do
  factory :article_part_page, class: Article::Part::Page, traits: [:ss_site, :ss_user, :cms_part] do
    route "article/page"
  end
end
