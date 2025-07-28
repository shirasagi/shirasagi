FactoryBot.define do
  factory :gws_workflow2_form_external, class: Gws::Workflow2::Form::External do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    url { "/#{unique_id}/" }
    order { rand(100 ) }
    description { "<p>" + Array.new(2) { "description-#{unique_id}" }.join("<br>") + "</p>" }
    memo { Array.new(2) { "memo-#{unique_id}" }.join("\n") }
    state { %w(public closed).sample }
  end
end
