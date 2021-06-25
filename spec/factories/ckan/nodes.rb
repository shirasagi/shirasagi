FactoryBot.define do
  factory :ckan_node_page, class: Ckan::Node::Page do
    name { unique_id }
    filename { name }
    route "ckan/page"
    ckan_url "http://example.com"
    ckan_basicauth_state "disabled"
    ckan_max_docs 10
    ckan_item_url "http://example.com"
  end
end
