FactoryGirl.define do
  factory :ezine_column, class: Ezine::Column do
    state "public"
    required "required"
    site_id { cms_site.id }
    association :node, factory: :ezine_node
  end
end
