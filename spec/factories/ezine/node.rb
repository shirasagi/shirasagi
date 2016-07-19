FactoryGirl.define do
  factory :ezine_node_page, class: Ezine::Node::Page, traits: [:cms_node] do
    route 'ezine/page'
    sender_name { unique_id }
    sender_email { "#{sender_name}@example.jp" }
  end

  factory :ezine_node_member_page, class: Ezine::Node::MemberPage, traits: [:cms_node] do
    route 'ezine/member_page'
  end

  factory :ezine_node_category_node, class: Ezine::Node::CategoryNode, traits: [:cms_node] do
    route 'ezine/category_node'
  end
end
