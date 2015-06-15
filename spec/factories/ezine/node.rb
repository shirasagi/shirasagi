FactoryGirl.define do
  factory :ezine_node, class: Cms::Node do
    site_id { cms_site.id }
    user_id { cms_user.id }
    name 'title'
    filename 'magazine'
    route 'magazine'
  end
end
