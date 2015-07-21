FactoryGirl.define do
  factory :article_page, class: Article::Page, traits: [:cms_page] do
    transient do
      site nil
      node nil
    end

    cur_site { site ? site : cms_site }
    filename { node ? "#{node.filename}/#{name}.html" : "dir/#{unique_id}.html" }
    route "article/page"
  end
end
