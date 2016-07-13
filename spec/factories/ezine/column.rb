FactoryGirl.define do
  factory :ezine_column, class: Ezine::Column do
    state "public"
    required "required"
    cur_site { cms_site }
    association :node, factory: :ezine_node_page
  end
end
