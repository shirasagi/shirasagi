FactoryGirl.define do
  factory :article_part_page, class: Article::Part::Page, traits: [:cms_part] do
    route "article/page"
  end
end
