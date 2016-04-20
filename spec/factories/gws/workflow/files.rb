FactoryGirl.define do
  factory :gws_workflow_file, class: Gws::Workflow::File do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }
    file_ids { [ create(:ss_temp_file).id ] }
  end
end
