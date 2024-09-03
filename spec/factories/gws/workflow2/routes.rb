FactoryBot.define do
  factory :gws_workflow2_route, class: Gws::Workflow2::Route do
    cur_site { gws_site }
    name { "name-#{unique_id}" }
    group_ids { [ gws_site.id ] }
    approvers do
      [ { level: 1, user_type: gws_user.class.name, user_id: gws_user.id, editable: "" }.with_indifferent_access ]
    end
    required_counts { Array.new(Gws::Workflow::Route::MAX_APPROVERS) { false } }
  end
end
