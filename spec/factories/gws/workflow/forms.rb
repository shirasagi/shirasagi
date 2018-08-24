FactoryBot.define do
  factory :gws_workflow_form, class: Gws::Workflow::Form do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "form-#{unique_id}" }
    order { rand(100 ) }
    state { %w(closed public).sample }
    agent_state { %w(disabled enabled).sample }
    memo { "memo-#{unique_id}" }
  end
end
