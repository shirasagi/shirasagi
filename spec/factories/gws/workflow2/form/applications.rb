FactoryBot.define do
  factory :gws_workflow2_form_application, class: Gws::Workflow2::Form::Application do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    order { rand(100 ) }
    state { %w(closed public).sample }
    agent_state { %w(disabled enabled).sample }
    description { "<p>" + Array.new(2) { "description-#{unique_id}" }.join("<br>") + "</p>" }
    memo { Array.new(2) { "memo-#{unique_id}" }.join("\n") }
    readable_setting_range { "public" }
  end
end
