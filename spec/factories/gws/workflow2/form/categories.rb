FactoryBot.define do
  factory :gws_workflow2_form_category, class: Gws::Workflow2::Form::Category do
    cur_site { gws_site }
    cur_user { gws_user }

    name { unique_id }
    color { unique_color }
    order { rand(100 ) }
  end
end
