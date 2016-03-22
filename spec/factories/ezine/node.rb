FactoryGirl.define do
  factory :ezine_node, class: Cms::Node do
    site_id { cms_site.id }
    user_id { cms_user.id }
    name 'title'
    filename 'magazine'
    route 'magazine'
  end

  factory :ezine_node_page, class: Ezine::Node::Page do
    site_id { cms_site.id }
    user_id { cms_user.id }
    route 'ezine/page'
    name 'ezine'
    filename 'ezine'
    sender_name "from"
    sender_email "from@example.jp"
  end
end
