FactoryGirl.define do
  factory :ezine_node, class: Cms::Node do
    cur_site { cms_site }
    cur_user { cms_user }
    name 'title'
    filename 'magazine'
    route 'magazine'
  end

  factory :ezine_node_page, class: Ezine::Node::Page do
    cur_site { cms_site }
    cur_user { cms_user }
    route 'ezine/page'
    name 'ezine'
    filename 'ezine'
    sender_name "from"
    sender_email "from@example.jp"
  end
end
