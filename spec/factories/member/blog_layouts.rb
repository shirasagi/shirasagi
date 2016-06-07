FactoryGirl.define do
  factory :member_blog_layout, class: Member::BlogLayout do
    site_id { cur_site.present? ? cur_site.id : cms_site.id }
    name { unique_id }
    filename { cur_node ? "#{cur_node.url}#{unique_id}.layout.html" : "#{unique_id}.layout.html" }
    html { "<html><body><div>{{ yield }}</div></body></html>" }
  end
end
