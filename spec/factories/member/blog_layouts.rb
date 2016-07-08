FactoryGirl.define do
  factory :member_blog_layout, class: Member::BlogLayout do
    cur_site { cms_site }
    name { unique_id }
    filename { cur_node ? "#{cur_node.url}#{unique_id}.layout.html" : "#{unique_id}.layout.html" }
    html { "<html><body><div>{{ yield }}</div></body></html>" }
  end
end
