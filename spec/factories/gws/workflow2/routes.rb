FactoryBot.define do
  factory :gws_workflow2_route, class: Gws::Workflow2::Route do
    cur_site { gws_site }
    name { "name-#{unique_id}" }
    order { rand(1..100) }
    group_ids { [ gws_site.id ] }
    approvers do
      [
        {
          _id: BSON::ObjectId.new.to_s, level: 1, user_type: gws_user.class.name, user_id: gws_user.id,
          editable: [ "", 1 ].sample, alternatable: [ "", 1 ].sample
        }.with_indifferent_access
      ]
    end
    required_counts { Array.new(Gws::Workflow::Route::MAX_APPROVERS) { false } }
  end
end
